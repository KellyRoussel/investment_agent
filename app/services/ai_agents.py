from typing import Dict
from urllib import response
from agents import Agent, Runner, WebSearchTool
import os

from jinja2 import Template
from openai import OpenAI
from domain.entities.investment import Investment, Vehicle
from prompts.orchestrator import orchestrator_prompt_template


trend_search_agent = Agent(
    name="Trend Search Agent",
    tools=[WebSearchTool()],
    instructions="""You search the web for market trends and investment opportunities. 
        Your search can be general about the market or specific to certain sectors or asset types or even specific to a potential investment (asset, company, ...).
    """,
)

data_agent = Agent(
    name="Data Agent",
    instructions="Your role is to gather relevant data about specific investments.",
    tools=[WebSearchTool()],
    output_type=Investment
)

async def fill_investment_data(name: str) -> Investment:
    client = OpenAI()
    result = client.responses.parse(
    model="gpt-4.1",
    tools=[ { "type": "web_search" },],
    input=[
        {"role": "system", 
         "content": f"Find all the information about the following investment: {name}. Answer in the provided json format."},
    ],
    text_format=Vehicle,
    )

    return result.output_parsed

async def launch_agents(user_portfolio: list[Investment], portfolio_metrics: Dict):

    orchestrator_instructions = Template(orchestrator_prompt_template).render(user_portfolio=user_portfolio, portfolio_metrics=portfolio_metrics)



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
                            input="""
                            You are an expert financial advisor. 
                            The user is Kelly, a 28-year-old AI engineer based in Lyon, France.
                            She has a moderate risk tolerance and is looking to invest for the medium and long term.
                            She is particularly interested in technology and sustainable investments.
                            She won't accept any investment in fossil fuels, military or any other unethical sectors.
                            Here is her current portfolio and its performance metrics:
                            {user_portfolio}
                            {portfolio_metrics}
                            It is really important that she keeps a diversified portfolio across different asset classes, sectors, geographies, risk levels etc...
                            Today is the end of december 2025 and she has 50 euros to invest this month.
                            Based on her profile, current portfolio and market trends, provide a detailed investment recommendation with precise investment options.""")
    return result.final_output
