"""
Modèle de base de données pour l'historique des prix.
"""
from enum import Enum as PyEnum

from sqlalchemy import (
    Column, Numeric, BigInteger, DateTime, String, 
    ForeignKey, Enum as SQLEnum, CheckConstraint
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from .base import BaseModel, GUID


class DataQuality(PyEnum):
    """Qualité des données de prix."""
    GOOD = "good"
    DELAYED = "delayed"
    ESTIMATED = "estimated"
    MISSING = "missing"


class PriceHistory(BaseModel):
    """Modèle historique des prix."""
    
    __tablename__ = "price_history"
    
    # Relations
    investment_id = Column(
        GUID,
        ForeignKey("investments.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        comment="ID de l'investissement"
    )
    
    # Données de prix
    price = Column(
        Numeric(15, 4),
        nullable=False,
        comment="Prix de clôture"
    )
    
    open_price = Column(
        Numeric(15, 4),
        nullable=True,
        comment="Prix d'ouverture"
    )
    
    high_price = Column(
        Numeric(15, 4),
        nullable=True,
        comment="Prix le plus haut"
    )
    
    low_price = Column(
        Numeric(15, 4),
        nullable=True,
        comment="Prix le plus bas"
    )
    
    close_price = Column(
        Numeric(15, 4),
        nullable=True,
        comment="Prix de clôture (peut différer du prix principal)"
    )
    
    adjusted_close = Column(
        Numeric(15, 4),
        nullable=True,
        comment="Prix de clôture ajusté (dividendes, splits)"
    )
    
    # Données de marché
    market_cap = Column(
        BigInteger,
        nullable=True,
        comment="Capitalisation boursière"
    )
    
    volume = Column(
        BigInteger,
        nullable=True,
        comment="Volume d'échanges"
    )
    
    dividend_amount = Column(
        Numeric(10, 4),
        nullable=True,
        comment="Montant du dividende"
    )
    
    split_ratio = Column(
        Numeric(8, 4),
        nullable=True,
        comment="Ratio de split (ex: 2.0 pour un split 2:1)"
    )
    
    # Métadonnées
    timestamp = Column(
        DateTime(timezone=True),
        nullable=False,
        index=True,
        comment="Horodatage des données"
    )
    
    source = Column(
        String(50),
        nullable=False,
        default="yahoo_finance",
        comment="Source des données (yahoo_finance, manual, etc.)"
    )
    
    data_quality = Column(
        SQLEnum(DataQuality),
        nullable=False,
        default=DataQuality.GOOD,
        comment="Qualité des données"
    )
    
    # Relations
    investment = relationship(
        "DBInvestment",
        back_populates="price_history",
        lazy="select"
    )
    
    # Contraintes
    __table_args__ = (
        CheckConstraint('price > 0', name='chk_positive_price'),
        CheckConstraint('open_price IS NULL OR open_price > 0', name='chk_positive_open_price'),
        CheckConstraint('high_price IS NULL OR high_price > 0', name='chk_positive_high_price'),
        CheckConstraint('low_price IS NULL OR low_price > 0', name='chk_positive_low_price'),
        CheckConstraint('close_price IS NULL OR close_price > 0', name='chk_positive_close_price'),
        CheckConstraint('adjusted_close IS NULL OR adjusted_close > 0', name='chk_positive_adjusted_close'),
        CheckConstraint('market_cap IS NULL OR market_cap >= 0', name='chk_non_negative_market_cap'),
        CheckConstraint('volume IS NULL OR volume >= 0', name='chk_non_negative_volume'),
        CheckConstraint('dividend_amount IS NULL OR dividend_amount >= 0', name='chk_non_negative_dividend'),
        CheckConstraint('split_ratio IS NULL OR split_ratio > 0', name='chk_positive_split_ratio'),
    )
    
    def __repr__(self) -> str:
        return f"<PriceHistory(id={self.id}, investment_id={self.investment_id}, price={self.price}, timestamp='{self.timestamp}')>"
