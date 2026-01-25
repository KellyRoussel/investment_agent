"""
Application configuration using environment variables.
"""
import os
from typing import Optional

from pydantic import ConfigDict
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = ConfigDict(
        env_file=".env",
        case_sensitive=True,
        extra="ignore",  # Ignore extra fields from .env
    )
    OPENAI_API_KEY: str = os.getenv("OPENAI__API_KEY", "")

    # Database
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/investment_portfolio"

    # JWT Configuration
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "")
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Application
    APP_NAME: str = "Investment Agent API"
    DEBUG: bool = False


settings = Settings()

# Validate JWT secret key
if not settings.JWT_SECRET_KEY:
    raise ValueError(
        "JWT_SECRET_KEY environment variable is required. "
        "Generate one with: openssl rand -hex 32"
    )
