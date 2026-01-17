from datetime import date, datetime, timedelta
from typing import Optional

import yfinance as yf

from app.models.investment import AssetType, MarketCapCategory


class YahooFinanceClient:
    """Client for Yahoo Finance via yfinance."""

    @staticmethod
    def _map_asset_type(quote_type: Optional[str]) -> AssetType:
        mapping = {
            "EQUITY": AssetType.STOCK,
            "ETF": AssetType.ETF,
            "CRYPTOCURRENCY": AssetType.CRYPTO,
            "BOND": AssetType.BOND,
            "MUTUALFUND": AssetType.MUTUAL_FUND,
            "REIT": AssetType.REIT,
        }
        return mapping.get((quote_type or "").upper(), AssetType.STOCK)

    @staticmethod
    def _map_country(country: Optional[str]) -> str:
        if not country:
            return "UNK"

        upper = country.upper()
        if len(upper) in (2, 3) and upper.isalpha():
            return upper

        name_mapping = {
            "UNITED STATES": "USA",
            "UNITED KINGDOM": "GBR",
            "CANADA": "CAN",
            "FRANCE": "FRA",
            "GERMANY": "DEU",
            "SPAIN": "ESP",
            "ITALY": "ITA",
            "SWITZERLAND": "CHE",
            "NETHERLANDS": "NLD",
            "BELGIUM": "BEL",
            "PORTUGAL": "PRT",
            "IRELAND": "IRL",
            "JAPAN": "JPN",
            "CHINA": "CHN",
            "HONG KONG": "HKG",
            "SINGAPORE": "SGP",
            "AUSTRALIA": "AUS",
            "NEW ZEALAND": "NZL",
            "BRAZIL": "BRA",
            "INDIA": "IND",
            "SWEDEN": "SWE",
            "NORWAY": "NOR",
            "DENMARK": "DNK",
            "FINLAND": "FIN",
            "AUSTRIA": "AUT",
        }
        return name_mapping.get(upper, "UNK")

    @staticmethod
    def _map_market_cap_category(market_cap: Optional[int]) -> Optional[MarketCapCategory]:
        if market_cap is None:
            return None
        if market_cap > 10_000_000_000:
            return MarketCapCategory.LARGE_CAP
        if market_cap > 2_000_000_000:
            return MarketCapCategory.MID_CAP
        if market_cap > 300_000_000:
            return MarketCapCategory.SMALL_CAP
        return MarketCapCategory.MICRO_CAP

    @staticmethod
    def _get_current_price(ticker: yf.Ticker, info: dict) -> Optional[float]:
        price = info.get("regularMarketPrice") or info.get("currentPrice")
        if price is not None:
            return float(price)

        data = ticker.history(period="1d")
        if not data.empty:
            return float(data["Close"].iloc[-1])
        data = ticker.history(period="5d")
        if not data.empty:
            return float(data["Close"].iloc[-1])
        return None

    @staticmethod
    def get_purchase_price(ticker_symbol: str, purchase_date: date) -> Optional[float]:
        print("Fetching purchase price for", ticker_symbol, "on", purchase_date)
        ticker = yf.Ticker(ticker_symbol)
        start = datetime.combine(purchase_date - timedelta(days=7), datetime.min.time())
        end = datetime.combine(purchase_date + timedelta(days=1), datetime.min.time())
        data = ticker.history(start=start, end=end)
        if data.empty:
            return None
        if getattr(data.index, "tz", None) is not None:
            data = data.tz_convert("UTC")
            data.index = data.index.tz_localize(None)
        cutoff = datetime.combine(purchase_date, datetime.max.time())
        data = data.loc[:cutoff]
        if data.empty:
            return None
        return float(data["Close"].iloc[-1])

    @staticmethod
    def get_latest_close(ticker_symbol: str) -> Optional[float]:
        print("Fetching latest close price for", ticker_symbol)
        ticker = yf.Ticker(ticker_symbol)
        data = ticker.history(period="5d")
        if data.empty:
            return None
        return float(data["Close"].iloc[-1])

    @staticmethod
    def get_investment_profile(ticker_symbol: str) -> dict:
        print("Fetching profile for ticker:", ticker_symbol)
        ticker = yf.Ticker(ticker_symbol)
        info = ticker.info or {}

        return {
            "symbol": (info.get("symbol") or ticker_symbol).upper(),
            "name": info.get("shortName") or info.get("longName") or ticker_symbol.upper(),
            "asset_type": YahooFinanceClient._map_asset_type(info.get("quoteType")),
            "country": YahooFinanceClient._map_country(info.get("country")),
            "sector": info.get("sector"),
            "industry": info.get("industry"),
            "market_cap_category": YahooFinanceClient._map_market_cap_category(info.get("marketCap")),
            "currency": (info.get("currency") or "USD").upper(),
            "current_price": YahooFinanceClient._get_current_price(ticker, info),
        }
