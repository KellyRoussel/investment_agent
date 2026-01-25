from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.database import get_db
from app.repositories import InvestmentRepository
from app.services.portfolio_calculator import PortfolioCalculator
from app.services.ai_agents import launch_agents_stream
from app.utils.auth import get_current_user
from app.models.user import User
from app.domain.entities.investment import Investment as DomainInvestment, Vehicle
from app.domain.value_objects import Money

router = APIRouter()


class RecommendationResponse(BaseModel):
    recommendation: str


def _db_investment_to_domain(db_investment) -> DomainInvestment:
    """Convert database investment model to domain entity."""
    vehicle = Vehicle(
        symbol=db_investment.symbol,
        name=db_investment.name,
        asset_type=db_investment.asset_type,
        country=db_investment.country,
        sector=db_investment.sector,
        industry=db_investment.industry,
        market_cap_category=db_investment.market_cap_category,
        current_price=Money(
            amount=float(db_investment.current_price),
            currency=db_investment.currency
        ) if db_investment.current_price else None,
        current_value=None,
    )

    return DomainInvestment(
        id=db_investment.id,
        user_id=db_investment.user_id,
        vehicle=vehicle,
        purchase_date=db_investment.purchase_date,
        purchase_price=Money(
            amount=float(db_investment.purchase_price),
            currency=db_investment.currency
        ),
        quantity=int(db_investment.quantity),
    )


@router.get("/recommendations/generate")
async def generate_recommendation(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> StreamingResponse:
    """
    Generate AI-powered investment recommendations with Server-Sent Events streaming.

    This endpoint streams events as the AI agents process the request, providing
    real-time visibility into tool calls, agent transitions, and intermediate outputs.

    Args:
        current_user: Current authenticated user
        db: Database session

    Returns:
        StreamingResponse with SSE events
    """
    investment_repo = InvestmentRepository(db)
    calculator = PortfolioCalculator(db)

    # Get user's portfolio
    investments = investment_repo.get_by_user(
        user_id=current_user.id,
        active_only=True,
        skip=0,
        limit=1000,
    )

    # Convert to domain entities
    portfolio = [_db_investment_to_domain(inv) for inv in investments]

    # Calculate portfolio metrics
    portfolio_metrics = calculator.calculate_portfolio_metrics(
        current_user.id,
        current_user.currency_preference
    )

    async def event_generator():
        try:
            async for event in launch_agents_stream(portfolio, portfolio_metrics):
                yield event.to_sse()
        except Exception as e:
            yield f"data: {{'type': 'error', 'message': '{str(e)}'}}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        }
    )
