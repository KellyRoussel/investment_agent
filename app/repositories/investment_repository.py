"""
Repository for Investment database operations.
"""
from datetime import date
from decimal import Decimal
from typing import List, Optional
from uuid import UUID

from sqlalchemy.orm import Session

from models.investment import DBInvestment, AssetType, MarketCapCategory


class InvestmentRepository:
    """Repository for Investment CRUD operations."""
    
    def __init__(self, db: Session):
        self.db = db
    
    def create(
        self,
        user_id: UUID,
        symbol: str,
        name: str,
        asset_type: AssetType,
        country: str,
        purchase_date: date,
        purchase_price: Decimal,
        quantity: Decimal,
        currency: str = "USD",
        current_price: Optional[Decimal] = None,
        sector: Optional[str] = None,
        industry: Optional[str] = None,
        market_cap_category: Optional[MarketCapCategory] = None,
        dividend_yield: Optional[Decimal] = None,
        expense_ratio: Optional[Decimal] = None,
        notes: Optional[str] = None
    ) -> DBInvestment:
        """
        Create a new investment.
        
        Args:
            user_id: ID of the user who owns the investment
            symbol: Investment symbol (e.g., AAPL)
            name: Name of the company/asset
            asset_type: Type of asset
            country: Country code (ISO 3166-1 alpha-3)
            purchase_date: Date of purchase
            purchase_price: Purchase price per unit
            quantity: Quantity purchased
            currency: Currency code (ISO 4217)
            current_price: Current price per unit
            sector: Business sector
            industry: Specific industry
            market_cap_category: Market cap category
            dividend_yield: Dividend yield
            expense_ratio: Expense ratio (for ETFs)
            notes: Personal notes
            
        Returns:
            Created Investment instance
        """
        investment = DBInvestment(
            user_id=user_id,
            symbol=symbol,
            name=name,
            asset_type=asset_type,
            country=country,
            purchase_date=purchase_date,
            purchase_price=purchase_price,
            quantity=quantity,
            currency=currency,
            current_price=current_price,
            sector=sector,
            industry=industry,
            market_cap_category=market_cap_category,
            dividend_yield=dividend_yield,
            expense_ratio=expense_ratio,
            notes=notes
        )
        self.db.add(investment)
        self.db.commit()
        self.db.refresh(investment)
        return investment
    
    def get_by_id(self, investment_id: UUID) -> Optional[DBInvestment]:
        """
        Get investment by ID.
        
        Args:
            investment_id: Investment UUID
            
        Returns:
            Investment instance or None if not found
        """
        return self.db.query(DBInvestment).filter(DBInvestment.id == investment_id).first()
    
    def get_by_user(
        self, 
        user_id: UUID, 
        active_only: bool = True,
        skip: int = 0, 
        limit: int = 100
    ) -> List[DBInvestment]:
        """
        Get all investments for a user.
        
        Args:
            user_id: User UUID
            active_only: Only return active investments
            skip: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            List of Investment instances
        """
        query = self.db.query(DBInvestment).filter(DBInvestment.user_id == user_id)
        
        if active_only:
            query = query.filter(DBInvestment.is_active == True)
        
        return query.offset(skip).limit(limit).all()
    
    def get_by_symbol(
        self, 
        user_id: UUID, 
        symbol: str
    ) -> List[DBInvestment]:
        """
        Get all investments for a specific symbol.
        
        Args:
            user_id: User UUID
            symbol: Investment symbol
            
        Returns:
            List of Investment instances
        """
        return self.db.query(DBInvestment).filter(
            DBInvestment.user_id == user_id,
            DBInvestment.symbol == symbol,
            DBInvestment.is_active == True
        ).all()
    
    def get_by_asset_type(
        self, 
        user_id: UUID, 
        asset_type: AssetType
    ) -> List[DBInvestment]:
        """
        Get all investments of a specific asset type.
        
        Args:
            user_id: User UUID
            asset_type: Type of asset
            
        Returns:
            List of Investment instances
        """
        return self.db.query(DBInvestment).filter(
            DBInvestment.user_id == user_id,
            DBInvestment.asset_type == asset_type,
            DBInvestment.is_active == True
        ).all()
    
    def update_current_price(
        self, 
        investment_id: UUID, 
        current_price: Decimal
    ) -> Optional[DBInvestment]:
        """
        Update the current price of an investment.
        
        Args:
            investment_id: Investment UUID
            current_price: New current price
            
        Returns:
            Updated Investment instance or None if not found
        """
        investment = self.get_by_id(investment_id)
        if investment:
            investment.current_price = current_price
            self.db.commit()
            self.db.refresh(investment)
        return investment
    
    def update(self, investment: DBInvestment) -> DBInvestment:
        """
        Update investment.
        
        Args:
            investment: Investment instance with updated data
            
        Returns:
            Updated Investment instance
        """
        self.db.commit()
        self.db.refresh(investment)
        return investment
    
    def deactivate(self, investment_id: UUID) -> bool:
        """
        Deactivate an investment (soft delete).
        
        Args:
            investment_id: Investment UUID
            
        Returns:
            True if deactivated, False if not found
        """
        investment = self.get_by_id(investment_id)
        if investment:
            investment.is_active = False
            self.db.commit()
            return True
        return False
    
    def delete(self, investment_id: UUID) -> bool:
        """
        Delete investment (hard delete).
        
        Args:
            investment_id: Investment UUID
            
        Returns:
            True if deleted, False if not found
        """
        investment = self.get_by_id(investment_id)
        if investment:
            self.db.delete(investment)
            self.db.commit()
            return True
        return False

