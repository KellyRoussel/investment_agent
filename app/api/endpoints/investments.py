from decimal import Decimal
from typing import Optional
from uuid import UUID

from agents import Session
from fastapi import APIRouter, Depends, HTTPException
from app.database import get_db
from app.models.api_schema import InvestmentCreateRequest, InvestmentUpdateRequest
from app.services.portfolio_calculator import PortfolioCalculator
from app.models.investment import DBInvestment
from app.repositories import InvestmentRepository
from app.schemas import InvestmentResponse

router = APIRouter()

def _to_decimal(value: Optional[float]) -> Optional[Decimal]:
    if value is None:
        return None
    return Decimal(str(value))


def _build_investment_response(
    investment: DBInvestment,
    calculator: PortfolioCalculator,
) -> InvestmentResponse:
    metrics = calculator.calculate_investment_metrics(investment)
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
        current_price=float(investment.current_price) if investment.current_price is not None else None,
        current_value=metrics["current_value"],
        gain_loss=metrics["gain_loss"],
        gain_loss_percent=metrics["gain_loss_percent"],
        dividend_yield=float(investment.dividend_yield) if investment.dividend_yield is not None else None,
        expense_ratio=float(investment.expense_ratio) if investment.expense_ratio is not None else None,
        notes=investment.notes,
        is_active=investment.is_active,
        performance_status=metrics["performance_status"],
    )


@router.post("/investments", response_model=InvestmentResponse)
def create_investment(
    payload: InvestmentCreateRequest,
    db: Session = Depends(get_db),
) -> InvestmentResponse:
    investment_repo = InvestmentRepository(db)
    calculator = PortfolioCalculator(db)

    created = investment_repo.create(
        user_id=payload.user_id,
        symbol=payload.investment.symbol,
        name=payload.investment.name,
        asset_type=payload.investment.asset_type,
        country=payload.investment.country,
        purchase_date=payload.investment.purchase_date,
        purchase_price=_to_decimal(payload.investment.purchase_price),
        quantity=_to_decimal(payload.investment.quantity),
        currency=payload.investment.currency,
        sector=payload.investment.sector,
        industry=payload.investment.industry,
        market_cap_category=payload.investment.market_cap_category,
        dividend_yield=_to_decimal(payload.investment.dividend_yield),
        expense_ratio=_to_decimal(payload.investment.expense_ratio),
        notes=payload.investment.notes,
    )

    return _build_investment_response(created, calculator)


@router.patch("/investments/{investment_id}", response_model=InvestmentResponse)
def update_investment(
    investment_id: UUID,
    payload: InvestmentUpdateRequest,
    db: Session = Depends(get_db),
) -> InvestmentResponse:
    investment_repo = InvestmentRepository(db)
    calculator = PortfolioCalculator(db)

    investment = investment_repo.get_by_id(investment_id)
    if investment is None:
        raise HTTPException(detail="Investment not found.")

    if payload.current_price is not None:
        investment.current_price = payload.current_price
    if payload.quantity is not None:
        investment.quantity = payload.quantity

    investment_repo.update(investment)
    return _build_investment_response(investment, calculator)