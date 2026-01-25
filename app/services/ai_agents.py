from typing import AsyncGenerator
from agents import Agent, Runner, WebSearchTool, ItemHelpers
import json
from app.config import settings
from app.models.portfolio_metrics import PortfolioMetrics
from app.domain.entities.investment import Investment
from agents import set_default_openai_key


class AgentEvent:
    """Represents a streaming event from the AI agents."""
    def __init__(self, event_type: str, data: dict):
        self.event_type = event_type
        self.data = data

    def to_sse(self) -> str:
        """Convert to Server-Sent Events format."""
        return f"data: {json.dumps({'type': self.event_type, **self.data})}\n\n"


RESEARCH_AGENT_INSTRUCTIONS = """You are a financial research specialist. Follow this structured workflow to find investment opportunities.

## WORKFLOW

### STEP 1: Market Discovery (Unbiased)
Search for current market trends WITHOUT considering user preferences yet. Focus on:
- "stock market trends January 2026"
- "best performing sectors 2026"
- "ETF inflows 2026" or "popular ETFs January 2026"
- "emerging market opportunities 2026"
Run 2-3 broad searches to get a comprehensive view of what's happening in the markets.

### STEP 2: Build Initial Candidate List
From your research, identify 5-6 specific investment opportunities (stocks, ETFs, funds).
For each, note: name, ticker symbol (if found), sector, and why it's trending.

### STEP 3: Ethical & Values Filter
Review each candidate against the user's ethical criteria provided in the context.
ELIMINATE any investment related to:
- Fossil fuels (oil, gas, coal)
- Military/defense/weapons
- Tobacco, gambling, or other controversial industries
Keep only investments that align with the user's values.

### STEP 4: Portfolio Diversification Check
Compare remaining candidates with the user's existing portfolio (provided in context).
Prioritize investments that:
- Fill gaps in geographic exposure (if user is heavy in one region)
- Add sector diversification (avoid doubling down on existing sectors)
- Match the user's risk tolerance
- Are affordable within the user's budget

### STEP 5: Deep Dive Research
For the top 3-4 candidates after filtering, search for more details:
- "[investment name] performance 2025 2026"
- "[investment name] analyst rating"
- Current price and recent trend
Gather concrete data: prices, YTD performance, expense ratios (for ETFs).

### STEP 6: Final Recommendation
Select the TOP 2 investments and present them with:
- Full name and ticker symbol
- Current price and where to buy (exchange)
- Why it's a good fit for this specific user
- Key risks to be aware of
- Suggested allocation of the user's budget between the two

## OUTPUT FORMAT
Structure your final answer as:
1. **Market Context** (2-3 sentences on current trends)
2. **Recommendation 1**: [Name] ([Ticker])
   - Price: X€ | Sector: Y | Geography: Z
   - Why it fits: ...
   - Risk: ...
3. **Recommendation 2**: [Name] ([Ticker])
   - (same format)
4. **Suggested Allocation**: How to split the budget

Be concise but precise. Always include ticker symbols and current prices when available.
"""




async def launch_agents_stream(user_portfolio: list[Investment], portfolio_metrics: PortfolioMetrics) -> AsyncGenerator[AgentEvent, None]:
    """
    Launch AI agents and yield streaming events.

    Yields AgentEvent objects for each significant event during execution.
    The final event will have type 'final_output' with the complete recommendation.
    """
    set_default_openai_key(settings.OPENAI_API_KEY)
    research_agent = Agent(
        model="gpt-4.1-mini-2025-04-14",
        name="Research Agent",
        instructions=RESEARCH_AGENT_INSTRUCTIONS,
        tools=[WebSearchTool()],
    )

    # Format portfolio for the agent
    portfolio_summary = []
    for inv in user_portfolio:
        portfolio_summary.append(f"- {inv.vehicle.name} ({inv.vehicle.symbol}): {inv.vehicle.sector or 'N/A'} sector, {inv.vehicle.country} region")

    user_context = f"""
## USER PROFILE
- Name: Kelly, 28 years old, AI engineer in Lyon, France
- Risk tolerance: Moderate
- Investment horizon: Medium to long term
- Budget this month: 50 EUR
- Interests: Technology, sustainable/ESG investments

## ETHICAL EXCLUSIONS (MUST AVOID)
- Fossil fuels (oil, gas, coal companies)
- Military, defense, weapons manufacturers
- Tobacco, gambling
- Any company with poor environmental or social practices

## CURRENT PORTFOLIO ({len(user_portfolio)} holdings)
{chr(10).join(portfolio_summary) if portfolio_summary else "Empty portfolio - first investment!"}

## DIVERSIFICATION METRICS
- Breakdown by country: {', '.join(f'{k}: {v.percentage}%' for k, v in portfolio_metrics.breakdown_by_country.items())}"
- Breakdown by sector: {', '.join(f'{k}: {v.percentage}%' for k, v in portfolio_metrics.breakdown_by_sector.items())}"
- Breakdown by asset type: {', '.join(f'{k}: {v.percentage}%' for k, v in portfolio_metrics.breakdown_by_asset_type.items())}"

## YOUR TASK
Find 2 investment recommendations for January 2026. Follow your workflow steps carefully.
Start with STEP 1: broad market research.
"""

    # save user_context to txt file for debugging
    with open("debug_user_context.txt", "w") as f:
        f.write(user_context)
    result = Runner.run_streamed(research_agent, input=user_context)

    async for event in result.stream_events():
        print(f"DEBUG: Event type: {event.type}")
        if event.type == "agent_updated_stream_event":
            yield AgentEvent("agent_change", {"agent_name": event.new_agent.name})
        elif event.type == "run_item_stream_event":
            print(f"DEBUG: Run item event type: {event.item.type}")
            if event.item.type == "tool_call_item":
                print(f"DEBUG: Tool call item: {event.item}")
                raw = event.item.raw_item
                raw_type_name = type(raw).__name__

                # Handle WebSearchTool (hosted tool)
                if raw_type_name == "ResponseFunctionWebSearch":
                    # Extract search query from the action if available
                    query = ""
                    if hasattr(raw, "action") and raw.action:
                        query = getattr(raw.action, "query", "") or ""
                    yield AgentEvent("tool_call", {
                        "tool_name": "web_search",
                        "arguments": json.dumps({"query": query}) if query else ""
                    })
                else:
                
                    yield AgentEvent("tool_call", {
                        "tool_name": event.item.raw_item.name,
                        "arguments": event.item.raw_item.arguments
                    })
            elif event.item.type == "tool_call_output_item":
                output_preview = str(event.item.output)[:1000]
                yield AgentEvent("tool_output", {"output": output_preview})
            elif event.item.type == "message_output_item":
                message_text = ItemHelpers.text_message_output(event.item)
                yield AgentEvent("message", {"content": message_text})

    yield AgentEvent("final_output", {"recommendation": result.final_output})
