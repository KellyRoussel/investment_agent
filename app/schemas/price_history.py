"""
Schemas for price history data.
"""
from datetime import datetime
from typing import List, Optional

from pydantic import Field

from app.models.price_history import DataQuality
from .base import BaseSchema


class PriceHistoryPoint(BaseSchema):
    """Single price history data point."""

    timestamp: datetime = Field(..., description="Timestamp of the price data")
    price: float = Field(..., description="Closing price")
    open_price: Optional[float] = Field(None, description="Opening price")
    high_price: Optional[float] = Field(None, description="High price")
    low_price: Optional[float] = Field(None, description="Low price")
    close_price: Optional[float] = Field(None, description="Closing price")
    adjusted_close: Optional[float] = Field(None, description="Adjusted closing price")
    volume: Optional[int] = Field(None, description="Trading volume")
    market_cap: Optional[int] = Field(None, description="Market capitalization")
    dividend_amount: Optional[float] = Field(None, description="Dividend amount")
    split_ratio: Optional[float] = Field(None, description="Stock split ratio")
    source: str = Field(..., description="Data source")
    data_quality: DataQuality = Field(..., description="Quality of the data")


class PriceHistoryResponse(BaseSchema):
    """Response containing price history data."""

    investment_id: str = Field(..., description="ID of the investment")
    symbol: str = Field(..., description="Investment symbol")
    data_points: List[PriceHistoryPoint] = Field(..., description="List of price history data points")
    total_points: int = Field(..., description="Total number of data points")
    start_date: Optional[datetime] = Field(None, description="Start date of the range")
    end_date: Optional[datetime] = Field(None, description="End date of the range")
