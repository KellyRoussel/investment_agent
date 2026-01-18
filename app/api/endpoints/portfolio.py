from collections import defaultdict
from datetime import date, datetime, timedelta
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status

from sqlalchemy.orm import Session

from app.clients.yahoo_finance import YahooFinanceClient
from app.database import get_db
from app.repositories import InvestmentRepository
from app.schemas.portfolio import PortfolioHistoryPoint, PortfolioHistoryResponse
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


@router.get("/portfolio/{user_id}/price-history", response_model=PortfolioHistoryResponse)
def get_portfolio_price_history(
    start_date: Optional[date] = Query(None, description="Start date for portfolio history (default: 30 days ago)"),
    end_date: Optional[date] = Query(None, description="End date for portfolio history (default: today)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> PortfolioHistoryResponse:
    investment_repo = InvestmentRepository(db)

    if end_date is None:
        end_date = date.today()
    if start_date is None:
        start_date = end_date - timedelta(days=30)

    investments = investment_repo.get_by_user(
        user_id=current_user.id,
        active_only=True,
        skip=0,
        limit=1000,
    )

    totals: dict[datetime, float] = defaultdict(float)
    for investment in investments:
        if investment.purchase_date and investment.purchase_date > end_date:
            continue
        history_start = (
            max(start_date, investment.purchase_date)
            if investment.purchase_date
            else start_date
        )
        history = YahooFinanceClient.get_price_history(
            investment.symbol,
            history_start,
            end_date,
        )
        for point in history:
            price = point.price
            if price is None:
                continue
            totals[point.timestamp] += float(price) * float(investment.quantity)

    data_points = [
        PortfolioHistoryPoint(timestamp=timestamp, total_value=value)
        for timestamp, value in sorted(totals.items(), key=lambda item: item[0])
    ]

    return PortfolioHistoryResponse(
        user_id=current_user.id,
        data_points=data_points,
        total_points=len(data_points),
        start_date=data_points[0].timestamp if data_points else None,
        end_date=data_points[-1].timestamp if data_points else None,
    )
