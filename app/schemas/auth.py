"""
Authentication request and response schemas.
"""
from typing import Optional

from pydantic import EmailStr, Field, field_validator

from .base import BaseSchema


class LoginRequest(BaseSchema):
    """Request schema for user login."""

    email: EmailStr = Field(..., description="User's email address")
    password: str = Field(..., min_length=8, description="User's password")


class RegisterRequest(BaseSchema):
    """Request schema for user registration."""

    email: EmailStr = Field(..., description="User's email address")
    password: str = Field(..., min_length=8, description="User's password (minimum 8 characters)")
    full_name: str = Field(..., min_length=1, max_length=255, description="User's full name")
    currency_preference: str = Field("USD", min_length=3, max_length=3, description="Preferred currency (ISO 4217)")
    risk_tolerance: Optional[str] = Field(None, description="Risk tolerance level")

    @field_validator('currency_preference')
    def validate_currency(cls, v):
        if not v.isalpha() or not v.isupper():
            raise ValueError('Currency must be a 3-letter ISO 4217 code in uppercase')
        return v

    @field_validator('password')
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        return v


class TokenResponse(BaseSchema):
    """Response schema for authentication tokens."""

    access_token: str = Field(..., description="JWT access token")
    refresh_token: str = Field(..., description="JWT refresh token")
    token_type: str = Field("bearer", description="Token type")
    expires_in: int = Field(..., description="Access token expiration time in seconds")


class RefreshRequest(BaseSchema):
    """Request schema for refreshing access token."""

    refresh_token: str = Field(..., description="Refresh token")
