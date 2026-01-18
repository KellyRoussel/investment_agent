from datetime import date
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, Field, model_validator


class InvestmentCreateRequest(BaseModel):
    account_type: Literal["CTO", "PEA"] = Field(..., description="Investment account type")
    ticker_symbol: Optional[str] = Field(None, min_length=1, max_length=20)
    isin: Optional[str] = Field(None, min_length=12, max_length=12)
    quantity: float = Field(..., gt=0)
    purchase_date: date

    @model_validator(mode="after")
    def validate_identifiers(self) -> "InvestmentCreateRequest":
        if self.account_type == "PEA":
            if not self.ticker_symbol:
                raise ValueError("ticker_symbol is required when account_type is PEA")
        else:
            if not self.isin:
                raise ValueError("isin is required when account_type is CTO")
        return self


class InvestmentUpdateRequest(BaseModel):
    ticker_symbol: str = Field(..., min_length=1, max_length=20)
