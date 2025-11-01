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


class Investment(BaseModel):
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
    
    # Prix actuel (SEUL prix stocké)
    current_price = Column(
        Numeric(15, 4),
        nullable=True,
        comment="Prix actuel unitaire"
    )
    
    # Métriques calculées à la volée via propriétés
    @property
    def current_value(self):
        """Calcule la valeur actuelle totale."""
        if self.current_price is None:
            return None
        return self.current_price * self.quantity
    
    @property
    def total_cost(self):
        """Calcule le coût total d'achat."""
        return self.purchase_price * self.quantity
    
    @property
    def gain_loss(self):
        """Calcule le gain/perte en valeur absolue."""
        if self.current_price is None:
            return None
        return self.current_value - self.total_cost
    
    @property
    def gain_loss_percent(self):
        """Calcule le gain/perte en pourcentage."""
        if self.current_price is None or self.total_cost == 0:
            return None
        return (self.gain_loss / self.total_cost) * 100
    
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
        CheckConstraint('current_price IS NULL OR current_price > 0', name='chk_positive_current_price'),
        CheckConstraint('purchase_date <= CURRENT_DATE', name='chk_purchase_date_not_future'),
    )
    
    def __repr__(self) -> str:
        return f"<Investment(id={self.id}, symbol='{self.symbol}', name='{self.name}', user_id={self.user_id})>"