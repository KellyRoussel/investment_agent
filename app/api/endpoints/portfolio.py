from uuid import UUID
from fastapi import APIRouter, Depends

from sqlalchemy.orm import Session

from app.database import get_db
from app.services.portfolio_calculator import PortfolioCalculator

router = APIRouter()

@router.get("/portfolio/{user_id}/metrics")
def get_portfolio_metrics(
    user_id: UUID,
    db: Session = Depends(get_db),
) -> dict:
    calculator = PortfolioCalculator(db)
    return calculator.calculate_portfolio_metrics(user_id)