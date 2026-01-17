from datetime import datetime
from typing import Optional, List
from uuid import UUID

from pydantic import Field

from app.models.user import RiskTolerance
from .base import BaseSchema, IDSchema, TimestampSchema


class UserCreate(BaseSchema):
    email: str = Field(..., min_length=3, max_length=255)
    password_hash: str = Field(..., min_length=8, max_length=255)
    full_name: str = Field(..., min_length=1, max_length=255)
    currency_preference: str = Field("USD", min_length=3, max_length=3)
    risk_tolerance: RiskTolerance = Field(RiskTolerance.MODERATE)


class UserUpdate(BaseSchema):
    email: Optional[str] = Field(None, min_length=3, max_length=255)
    password_hash: Optional[str] = Field(None, min_length=8, max_length=255)
    full_name: Optional[str] = Field(None, min_length=1, max_length=255)
    currency_preference: Optional[str] = Field(None, min_length=3, max_length=3)
    risk_tolerance: Optional[RiskTolerance] = Field(None)
    is_active: Optional[bool] = Field(None)


class UserResponse(IDSchema, TimestampSchema):
    email: str = Field(..., description="User email")
    full_name: str = Field(..., description="User full name")
    currency_preference: str = Field(..., description="Preferred currency")
    risk_tolerance: RiskTolerance = Field(..., description="Risk tolerance")
    is_active: bool = Field(..., description="Whether the account is active")
    email_verified: bool = Field(..., description="Whether email is verified")
    last_login: Optional[datetime] = Field(None, description="Last login timestamp")


class UserListResponse(BaseSchema):
    items: List[UserResponse] = Field(..., description="List of users")
    total: int = Field(..., ge=0, description="Total number of users")
    limit: int = Field(..., ge=1, description="Limit applied")
    offset: int = Field(..., ge=0, description="Offset applied")
