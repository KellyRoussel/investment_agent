"""
Modèle de base de données pour les investissements.
"""
from decimal import Decimal
from enum import Enum as PyEnum
from typing import List, Optional

from sqlalchemy import (
    Column, String, Date, Numeric, Boolean, Text, 
    ForeignKey, Enum as SQLEnum, CheckConstraint
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.domain.entities.investment import Investment
from app.domain.value_objects.money import Money
from app.domain.value_objects.percentage import Percentage

from .base import BaseModel, GUID


class AssetType(PyEnum):
    """Types d'actifs supportés."""
    STOCK = "stock"
    ETF = "etf"
    CRYPTO = "crypto"
    BOND = "bond"
    COMMODITY = "commodity"
    REIT = "reit"
    MUTUAL_FUND = "mutual_fund"


class MarketCapCategory(PyEnum):
    """Catégories de capitalisation boursière."""
    LARGE_CAP = "large_cap"      # > $10B
    MID_CAP = "mid_cap"          # $2B - $10B
    SMALL_CAP = "small_cap"      # $300M - $2B
    MICRO_CAP = "micro_cap"      # < $300M


class DBInvestment(BaseModel):
    """Modèle investissement."""
    
    __tablename__ = "investments"
    
    # Relations
    user_id = Column(
        GUID,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        comment="ID de l'utilisateur propriétaire"
    )
    
    # Informations de base
    symbol = Column(
        String(20),
        nullable=False,
        comment="Symbole de l'investissement (ex: AAPL)"
    )
    
    name = Column(
        String(255),
        nullable=False,
        comment="Nom de l'entreprise/actif"
    )
    
    # Classification
    asset_type = Column(
        SQLEnum(AssetType),
        nullable=False,
        comment="Type d'actif"
    )
    
    country = Column(
        String(3),
        nullable=False,
        comment="Code pays ISO 3166-1 alpha-3"
    )
    
    sector = Column(
        String(100),
        nullable=True,
        comment="Secteur d'activité"
    )
    
    industry = Column(
        String(100),
        nullable=True,
        comment="Industrie spécifique"
    )
    
    market_cap_category = Column(
        SQLEnum(MarketCapCategory),
        nullable=True,
        comment="Catégorie de capitalisation boursière"
    )
    
    # Informations d'achat
    purchase_date = Column(
        Date,
        nullable=False,
        comment="Date d'achat"
    )
    
    purchase_price = Column(
        Numeric(15, 4),
        nullable=False,
        comment="Prix d'achat unitaire"
    )
    
    quantity = Column(
        Numeric(15, 8),
        nullable=False,
        comment="Quantité détenue"
    )
    
    currency = Column(
        String(3),
        nullable=False,
        default="USD",
        comment="Devise de l'investissement (ISO 4217)"
    )
    
    @property
    def total_cost(self):
        """Calcule le coût total d'achat."""
        return self.purchase_price * self.quantity

    # Informations supplémentaires
    dividend_yield = Column(
        Numeric(5, 4),
        nullable=True,
        comment="Rendement de dividende"
    )
    
    expense_ratio = Column(
        Numeric(5, 4),
        nullable=True,
        comment="Ratio de frais (pour ETF/fonds)"
    )
    
    notes = Column(
        Text,
        nullable=True,
        comment="Notes personnelles"
    )
    
    # Statut
    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
        comment="Indique si l'investissement est actif"
    )
    
    # Relations
    user = relationship(
        "User",
        back_populates="investments",
        lazy="select"
    )
    
    price_history = relationship(
        "PriceHistory",
        back_populates="investment",
        cascade="all, delete-orphan",
        lazy="select",
        order_by="PriceHistory.timestamp.desc()"
    )
    
    transactions = relationship(
        "InvestmentTransaction",
        back_populates="investment",
        cascade="all, delete-orphan",
        lazy="select",
        order_by="InvestmentTransaction.transaction_date.desc()"
    )
    
    # Contraintes
    __table_args__ = (
        CheckConstraint('quantity > 0', name='chk_positive_quantity'),
        CheckConstraint('purchase_price > 0', name='chk_positive_purchase_price'),
        CheckConstraint('purchase_date <= CURRENT_DATE', name='chk_purchase_date_not_future'),
    )
    
    def __repr__(self) -> str:
        return f"<Investment(id={self.id}, symbol='{self.symbol}', name='{self.name}', user_id={self.user_id})>"
    
    def to_domain(self) -> Investment:
        return Investment(
            id=self.id,
            symbol=self.symbol,
            name=self.name,
            user_id=self.user_id,
            asset_type=self.asset_type,
            country=self.country,
            purchase_date=self.purchase_date,
            purchase_price=Money(amount=self.purchase_price, currency=self.currency),
            quantity=self.quantity,
            currency=self.currency,
            sector=self.sector,
            industry=self.industry,
            market_cap_category=self.market_cap_category,
            dividend_yield=Percentage(self.dividend_yield) if self.dividend_yield is not None else None,
            expense_ratio=Percentage(self.expense_ratio) if self.expense_ratio is not None else None,
            notes=self.notes,
            is_active=self.is_active
        )
