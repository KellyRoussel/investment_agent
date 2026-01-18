from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status

from sqlalchemy.orm import Session

from app.database import get_db
from app.services.portfolio_calculator import PortfolioCalculator
from app.utils.auth import get_current_user
from app.models.user import User

router = APIRouter()

@router.get("/portfolio/{user_id}/metrics")
def get_portfolio_metrics(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:

    calculator = PortfolioCalculator(db)
    return calculator.calculate_portfolio_metrics(current_user.id)