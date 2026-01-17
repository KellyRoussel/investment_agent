from decimal import Decimal
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, Field, model_validator

from app.schemas.investment import InvestmentCreate


class InvestmentCreateRequest(BaseModel):
    user_id: UUID
    investment: InvestmentCreate


class InvestmentUpdateRequest(BaseModel):
    current_price: Optional[Decimal] = Field(None, gt=0)
    quantity: Optional[Decimal] = Field(None, gt=0)

    @model_validator(mode="after")
    def validate_payload(self):
        if self.current_price is None and self.quantity is None:
            raise ValueError("Provide current_price or quantity to update.")
        return self