from datetime import date
from uuid import UUID
from pydantic import BaseModel, Field


class InvestmentCreateRequest(BaseModel):
    user_id: UUID
    ticker_symbol: str = Field(..., min_length=1, max_length=20)
    quantity: float = Field(..., gt=0)
    purchase_date: date
    


class InvestmentUpdateRequest(BaseModel):
    ticker_symbol: str = Field(..., min_length=1, max_length=20)
