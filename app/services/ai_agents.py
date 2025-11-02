from typing import Dict
from agents import Agent, Runner
import os

from jinja2 import Template
from domain.entities.investment import Investment
from prompts.orchestrator import orchestrator_prompt_template


os.environ["OPENAI_API_KEY"] = "your_openai_api_key_here"


async def launch_agents(user_portfolio: list[Investment], portfolio_metrics: Dict):

    orchestrator_instructions = Template(orchestrator_prompt_template).render(user_portfolio=user_portfolio, portfolio_metrics=portfolio_metrics)

    trend_search_agent = Agent(
        name="Trend Search Agent",
        tools=["web_search"],
        instructions="""You search the web for market trends and investment opportunities. 
            Your search can be general about the market or specific to certain sectors or asset types or even specific to a potential investment (asset, company, ...).
        """,
    )

    data_agent = Agent(
        name="Data Agent",
        instructions="Your role is to gather relevant data about specific investments.",
        tools=["web_search"],
        output_type=Investment
    )

    orchestrator_agent = Agent(
        name="Orchestrator agent",
        instructions=orchestrator_instructions,
        tools = [
            trend_search_agent.as_tool(
                tool_name="trend_search_agent",
                tool_description="Use this tool to search for market trends and investment opportunities - general or specific."
            ),
          data_agent.as_tool(
                tool_name="data_agent",
                tool_description="Use this tool to gather relevant data about specific investments."
            )
        ],
    )

    
    result = await Runner.run(orchestrator_agent,
                            input="I have 50 euros to invest this month. What should I do?")
    return result.final_output
