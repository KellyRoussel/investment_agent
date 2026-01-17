import os
import sys

from fastapi import FastAPI

from app.api.endpoints.investments import router as investments_router
from app.api.endpoints.portfolio import router as portfolio_router



from app.services.portfolio_calculator import PortfolioCalculator

app = FastAPI(title="Investment Agent API")
app.include_router(investments_router)
app.include_router(portfolio_router)


