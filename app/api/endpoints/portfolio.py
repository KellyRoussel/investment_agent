from collections import defaultdict
from datetime import date, datetime, timedelta
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status

from sqlalchemy.orm import Session

from app.clients.yahoo_finance import YahooFinanceClient
from app.database import get_db
from app.models.portfolio_metrics import PortfolioMetrics
from app.repositories import InvestmentRepository
from app.schemas.portfolio import PortfolioHistoryPoint, PortfolioHistoryResponse
from app.services.portfolio_calculator import PortfolioCalculator
from app.services.currency_converter import CurrencyConverter
from app.utils.auth import get_current_user
from app.models.user import User

router = APIRouter()

@router.get("/portfolio/{user_id}/metrics")
def get_portfolio_metrics(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> PortfolioMetrics:

    calculator = PortfolioCalculator(db)
    return calculator.calculate_portfolio_metrics(current_user.id, current_user.currency_preference)


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

    user_currency = current_user.currency_preference

    # Collect all unique currencies and fetch exchange rate histories
    currencies = set(inv.currency for inv in investments if inv.currency != user_currency)
    exchange_rate_histories = {}
    for currency in currencies:
        exchange_rate_histories[currency] = CurrencyConverter.get_exchange_rate_history(
            currency,
            user_currency,
            start_date,
            end_date
        )

    totals: dict[date, float] = defaultdict(float)
    costs: dict[date, float] = defaultdict(float)

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

        # Convert purchase price to user's currency using the exchange rate at purchase date
        purchase_price_in_user_currency = float(investment.purchase_price)
        if investment.currency != user_currency and investment.purchase_date:
            # Use get_exchange_rate directly to fetch the rate for purchase_date,
            # since the exchange_rate_histories only contains rates within the graph date range
            exchange_rate = CurrencyConverter.get_exchange_rate(
                investment.currency,
                user_currency,
                investment.purchase_date
            )
            if exchange_rate:
                purchase_price_in_user_currency = float(investment.purchase_price) * exchange_rate

        for point in history:
            # if point date is 2025-11-27, print value
            price = point.price
            if price is None:
                continue

            # Normalize timestamp to date only
            point_date = point.timestamp.date()

            # Convert price to user's currency
            if investment.currency == user_currency:
                converted_price = price
            else:
                # Get exchange rate for this date
                rates = exchange_rate_histories.get(investment.currency, {})
                # lookup by date only (ignore time)
                exchange_rate = rates.get(
                    datetime.combine(point_date, datetime.min.time())
                )
                converted_price = price * exchange_rate if exchange_rate else price

            totals[point_date] += float(converted_price) * float(investment.quantity)
            costs[point_date] += float(purchase_price_in_user_currency) * float(investment.quantity)

    data_points = [
        PortfolioHistoryPoint(
            timestamp=date_val,
            total_value=totals[date_val],
            total_cost=costs[date_val],
            total_gain_loss=totals[date_val] - costs[date_val]
        )
        for date_val in sorted(totals.keys())
    ]
    

    return PortfolioHistoryResponse(
        user_id=current_user.id,
        data_points=data_points,
        total_points=len(data_points),
        start_date=data_points[0].timestamp if data_points else None,
        end_date=data_points[-1].timestamp if data_points else None,
    )
