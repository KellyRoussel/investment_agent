"""
Service for converting currencies using historical exchange rates from Yahoo Finance.
"""
from datetime import date, datetime, timedelta
from typing import Dict, Optional
from functools import lru_cache

from app.clients.yahoo_finance import YahooFinanceClient


class CurrencyConverter:
    """Service for currency conversion using Yahoo Finance exchange rates."""

    @staticmethod
    def _get_currency_pair_symbol(from_currency: str, to_currency: str) -> str:
        """
        Get the Yahoo Finance symbol for a currency pair.

        Args:
            from_currency: Source currency code (e.g., 'EUR')
            to_currency: Target currency code (e.g., 'USD')

        Returns:
            Yahoo Finance currency pair symbol (e.g., 'EURUSD=X')
        """
        if from_currency == to_currency:
            return None
        return f"{from_currency}{to_currency}=X"

    @staticmethod
    @lru_cache(maxsize=1000)
    def get_exchange_rate(from_currency: str, to_currency: str, target_date: date) -> Optional[float]:
        """
        Get the exchange rate for a specific date.

        Args:
            from_currency: Source currency code (e.g., 'EUR')
            to_currency: Target currency code (e.g., 'USD')
            target_date: Date for which to get the exchange rate

        Returns:
            Exchange rate or None if not available
        """
        if from_currency == to_currency:
            return 1.0

        symbol = CurrencyConverter._get_currency_pair_symbol(from_currency, to_currency)
        if not symbol:
            return 1.0

        try:
            # Get price history for a week around the target date to handle weekends/holidays
            history = YahooFinanceClient.get_price_history(
                symbol,
                target_date - timedelta(days=7),
                target_date
            )

            if not history:
                print(f"No exchange rate data found for {from_currency} to {to_currency} on {target_date}")
                return None

            # Get the closest price to the target date
            return history[-1].price
        except Exception as e:
            print(f"Error fetching exchange rate for {from_currency} to {to_currency}: {e}")
            return None

    @staticmethod
    def get_exchange_rate_history(
        from_currency: str,
        to_currency: str,
        start_date: date,
        end_date: date
    ) -> Dict[datetime, float]:
        """
        Get historical exchange rates for a date range.

        Args:
            from_currency: Source currency code (e.g., 'EUR')
            to_currency: Target currency code (e.g., 'USD')
            start_date: Start date
            end_date: End date

        Returns:
            Dictionary mapping timestamps to exchange rates
        """
        if from_currency == to_currency:
            # Create a dict with all dates in range set to 1.0
            result = {}
            current = datetime.combine(start_date, datetime.min.time())
            end = datetime.combine(end_date, datetime.min.time())
            while current <= end:
                result[current] = 1.0
                current += timedelta(days=1)
            return result

        symbol = CurrencyConverter._get_currency_pair_symbol(from_currency, to_currency)
        if not symbol:
            return {}

        try:
            history = YahooFinanceClient.get_price_history(symbol, start_date, end_date)
            return {point.timestamp: point.price for point in history if point.price is not None}
        except Exception as e:
            print(f"Error fetching exchange rate history for {from_currency} to {to_currency}: {e}")
            return {}

    @staticmethod
    def convert_amount(
        amount: float,
        from_currency: str,
        to_currency: str,
        conversion_date: date = None
    ) -> Optional[float]:
        """
        Convert an amount from one currency to another.

        Args:
            amount: Amount to convert
            from_currency: Source currency code
            to_currency: Target currency code
            conversion_date: Date for conversion (default: today)

        Returns:
            Converted amount or None if conversion failed
        """
        if conversion_date is None:
            conversion_date = date.today()

        rate = CurrencyConverter.get_exchange_rate(from_currency, to_currency, conversion_date)
        if rate is None:
            return None

        return amount * rate
