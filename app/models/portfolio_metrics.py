
from decimal import Decimal
from typing import Dict, List, Optional
from uuid import UUID

from pydantic import BaseModel, Field


class PortfolioBreakdownItem(BaseModel):
    value: float = Field(..., description="Category value")
    percentage: float = Field(..., description="Category percentage")
    count: int = Field(..., ge=0, description="Number of investments in category")


class PortfolioBreakdownMap(BaseModel):
    breakdowns: Dict[str, PortfolioBreakdownItem] = Field(default_factory=dict)


class PortfolioPerformer(BaseModel):
    investment_id: UUID = Field(..., description="Investment ID")
    symbol: str = Field(..., description="Investment symbol")
    name: str = Field(..., description="Investment name")
    gain_loss_percent: Decimal = Field(..., description="Gain/loss percentage")


class PortfolioPerformers(BaseModel):
    top_performers: List[PortfolioPerformer] = Field(default_factory=list)
    worst_performers: List[PortfolioPerformer] = Field(default_factory=list)


class DiversificationScore(BaseModel):
    score: float = Field(..., ge=0, description="Diversification score")


class PortfolioMetrics(BaseModel):
    user_id: UUID
    total_value: Decimal
    total_cost: Decimal
    total_gain_loss: Decimal
    total_gain_loss_percent: Decimal
    diversification_score: float
    investment_count: int
    breakdown_by_country: Dict[str, PortfolioBreakdownItem] = Field(default_factory=dict)
    breakdown_by_sector: Dict[str, PortfolioBreakdownItem] = Field(default_factory=dict)
    breakdown_by_asset_type: Dict[str, PortfolioBreakdownItem] = Field(default_factory=dict)
    top_performers: List[PortfolioPerformer] = Field(default_factory=list)
    worst_performers: List[PortfolioPerformer] = Field(default_factory=list)
    currency: str


class InvestmentMetrics(BaseModel):
    current_value: Optional[float]
    gain_loss: Optional[float]
    gain_loss_percent: Optional[float]
    performance_status: str

