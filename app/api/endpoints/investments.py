from datetime import date, timedelta
from decimal import Decimal
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.clients.open_figi import OpenFigiClient
from app.clients.yahoo_finance import YahooFinanceClient
from app.database import get_db
from app.models.api_schema import InvestmentCreateRequest, InvestmentUpdateRequest
from app.models.investment import DBInvestment
from app.repositories import InvestmentRepository
from app.schemas import InvestmentResponse
from app.schemas.price_history import PriceHistoryResponse
from app.utils.auth import get_current_user
from app.models.user import User

router = APIRouter()

def _to_decimal(value: Optional[float]) -> Optional[Decimal]:
    if value is None:
        return None
    return Decimal(str(value))


def _build_investment_response(
    investment: DBInvestment,
) -> InvestmentResponse:
    return InvestmentResponse(
        id=investment.id,
        created_at=investment.created_at,
        updated_at=investment.updated_at,
        user_id=investment.user_id,
        symbol=investment.symbol,
        name=investment.name,
        asset_type=investment.asset_type,
        country=investment.country,
        sector=investment.sector,
        industry=investment.industry,
        market_cap_category=investment.market_cap_category,
        purchase_date=investment.purchase_date,
        purchase_price=float(investment.purchase_price),
        quantity=float(investment.quantity),
        currency=investment.currency,
        dividend_yield=float(investment.dividend_yield) if investment.dividend_yield is not None else None,
        expense_ratio=float(investment.expense_ratio) if investment.expense_ratio is not None else None,
        notes=investment.notes,
        is_active=investment.is_active,
    )


@router.post("/investments", response_model=InvestmentResponse)
def create_investment(
    payload: InvestmentCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> InvestmentResponse:
    investment_repo = InvestmentRepository(db)

    if payload.account_type == "PEA":
        ticker_symbol = payload.ticker_symbol
    else:
        try:
            ticker_symbol = OpenFigiClient.isin_to_ticker(payload.isin)
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(exc),
            ) from exc

    if not ticker_symbol:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unable to resolve ticker_symbol from the provided input.",
        )

    profile = YahooFinanceClient.get_investment_profile(ticker_symbol)
    purchase_price = YahooFinanceClient.get_purchase_price(
        ticker_symbol,
        payload.purchase_date,
    )

    if purchase_price is None:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Unable to fetch purchase price for the provided date.",
        )

    created = investment_repo.create(
        user_id=current_user.id,
        symbol=profile["symbol"],
        name=profile["name"],
        asset_type=profile["asset_type"],
        country=profile["country"],
        purchase_date=payload.purchase_date,
        purchase_price=_to_decimal(purchase_price),
        quantity=Decimal(payload.quantity),
        currency=profile["currency"],
        sector=profile["sector"],
        industry=profile["industry"],
        market_cap_category=profile["market_cap_category"],
    )

    return _build_investment_response(created)


@router.patch("/investments/{investment_id}", response_model=InvestmentResponse)
def update_investment(
    investment_id: UUID,
    payload: InvestmentUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> InvestmentResponse:
    investment_repo = InvestmentRepository(db)

    investment = investment_repo.get_by_id(investment_id)
    if investment is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Investment not found.",
        )

    # Verify ownership
    if investment.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this investment",
        )

    profile = YahooFinanceClient.get_investment_profile(payload.ticker_symbol)

    investment.symbol = profile["symbol"]
    investment.name = profile["name"]
    investment.asset_type = profile["asset_type"]
    investment.country = profile["country"]
    investment.sector = profile["sector"]
    investment.industry = profile["industry"]
    investment.market_cap_category = profile["market_cap_category"]
    investment.currency = profile["currency"]

    investment_repo.update(investment)
    return _build_investment_response(investment)


@router.get("/users/{user_id}/investments", response_model=list[InvestmentResponse])
def list_user_investments(
    skip: int = 0,
    limit: int = 100,
    active_only: bool = True,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[InvestmentResponse]:

    investment_repo = InvestmentRepository(db)

    investments = investment_repo.get_by_user(
        user_id=current_user.id,
        active_only=active_only,
        skip=skip,
        limit=limit,
    )
    return [_build_investment_response(inv) for inv in investments]


@router.get("/investments/{investment_id}/price-history", response_model=PriceHistoryResponse)
def get_price_history(
    investment_id: UUID,
    start_date: Optional[date] = Query(None, description="Start date for price history (default: 30 days ago)"),
    end_date: Optional[date] = Query(None, description="End date for price history (default: today)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> PriceHistoryResponse:
    """
    Get price history for an investment within a date range.

    Args:
        investment_id: ID of the investment
        start_date: Start date (default: 30 days ago)
        end_date: End date (default: today)
        current_user: Current authenticated user
        db: Database session

    Returns:
        PriceHistoryResponse with historical price data

    Raises:
        HTTPException 404: If investment not found
        HTTPException 403: If user doesn't own the investment
    """
    investment_repo = InvestmentRepository(db)

    # Verify investment exists
    investment = investment_repo.get_by_id(investment_id)
    if investment is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Investment not found",
        )

    # Verify ownership
    if investment.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view this investment's price history",
        )

    # Set default dates if not provided
    if end_date is None:
        end_date = date.today()
    if start_date is None:
        start_date = end_date - timedelta(days=30)

    # Fetch price history from Yahoo Finance
    price_histories = YahooFinanceClient.get_price_history(
        investment.symbol,
        start_date,
        end_date,
    )

    

    return PriceHistoryResponse(
        investment_id=str(investment_id),
        symbol=investment.symbol,
        data_points=price_histories,
        total_points=len(price_histories),
        start_date=price_histories[0].timestamp if price_histories else None,
        end_date=price_histories[-1].timestamp if price_histories else None,
    )


@router.delete("/investments/{investment_id}")
def delete_investment(
    investment_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    investment_repo = InvestmentRepository(db)

    investment = investment_repo.get_by_id(investment_id)
    if investment is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Investment not found.",
        )

    # Verify ownership
    if investment.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to delete this investment",
        )

    investment_repo.delete(investment_id)
    return {"detail": "Investment deleted successfully."}
