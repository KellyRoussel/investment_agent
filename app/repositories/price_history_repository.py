"""
Repository for PriceHistory database operations.
"""
from datetime import datetime, date
from typing import List, Optional
from uuid import UUID

from sqlalchemy.orm import Session
from sqlalchemy import and_

from app.models.price_history import PriceHistory, DataQuality


class PriceHistoryRepository:
    """Repository for PriceHistory CRUD operations."""

    def __init__(self, db: Session):
        self.db = db

    def create(
        self,
        investment_id: UUID,
        price: float,
        timestamp: datetime,
        open_price: Optional[float] = None,
        high_price: Optional[float] = None,
        low_price: Optional[float] = None,
        close_price: Optional[float] = None,
        adjusted_close: Optional[float] = None,
        market_cap: Optional[int] = None,
        volume: Optional[int] = None,
        dividend_amount: Optional[float] = None,
        split_ratio: Optional[float] = None,
        source: str = "yahoo_finance",
        data_quality: DataQuality = DataQuality.GOOD,
    ) -> PriceHistory:
        """
        Create a new price history entry.

        Args:
            investment_id: ID of the investment
            price: Closing price
            timestamp: Timestamp of the price data
            open_price: Opening price
            high_price: High price
            low_price: Low price
            close_price: Closing price (can differ from main price)
            adjusted_close: Adjusted closing price
            market_cap: Market capitalization
            volume: Trading volume
            dividend_amount: Dividend amount
            split_ratio: Stock split ratio
            source: Data source
            data_quality: Quality of the data

        Returns:
            Created PriceHistory instance
        """
        price_history = PriceHistory(
            investment_id=investment_id,
            price=price,
            timestamp=timestamp,
            open_price=open_price,
            high_price=high_price,
            low_price=low_price,
            close_price=close_price,
            adjusted_close=adjusted_close,
            market_cap=market_cap,
            volume=volume,
            dividend_amount=dividend_amount,
            split_ratio=split_ratio,
            source=source,
            data_quality=data_quality,
        )
        self.db.add(price_history)
        self.db.commit()
        self.db.refresh(price_history)
        return price_history

    def get_by_investment(
        self,
        investment_id: UUID,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
    ) -> List[PriceHistory]:
        """
        Get price history for an investment within a date range.

        Args:
            investment_id: ID of the investment
            start_date: Start date (inclusive). If None, no lower bound.
            end_date: End date (inclusive). If None, no upper bound.

        Returns:
            List of PriceHistory entries sorted by timestamp ascending
        """
        query = self.db.query(PriceHistory).filter(
            PriceHistory.investment_id == investment_id
        )

        if start_date:
            # Convert date to datetime at start of day
            start_datetime = datetime.combine(start_date, datetime.min.time())
            query = query.filter(PriceHistory.timestamp >= start_datetime)

        if end_date:
            # Convert date to datetime at end of day
            end_datetime = datetime.combine(end_date, datetime.max.time())
            query = query.filter(PriceHistory.timestamp <= end_datetime)

        return query.order_by(PriceHistory.timestamp.asc()).all()

    def get_latest(self, investment_id: UUID) -> Optional[PriceHistory]:
        """
        Get the most recent price history entry for an investment.

        Args:
            investment_id: ID of the investment

        Returns:
            Latest PriceHistory instance or None if not found
        """
        return (
            self.db.query(PriceHistory)
            .filter(PriceHistory.investment_id == investment_id)
            .order_by(PriceHistory.timestamp.desc())
            .first()
        )

    def bulk_create(self, price_histories: List[PriceHistory]) -> List[PriceHistory]:
        """
        Bulk create price history entries.

        Args:
            price_histories: List of PriceHistory instances

        Returns:
            List of created PriceHistory instances
        """
        self.db.add_all(price_histories)
        self.db.commit()
        for ph in price_histories:
            self.db.refresh(ph)
        return price_histories

    def delete_by_investment(self, investment_id: UUID) -> int:
        """
        Delete all price history entries for an investment.

        Args:
            investment_id: ID of the investment

        Returns:
            Number of deleted entries
        """
        count = (
            self.db.query(PriceHistory)
            .filter(PriceHistory.investment_id == investment_id)
            .delete()
        )
        self.db.commit()
        return count
