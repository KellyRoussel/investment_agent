"""
Modèle de base de données pour les transactions d'investissement.
"""
from datetime import date
from decimal import Decimal
from enum import Enum as PyEnum
from typing import Optional

from sqlalchemy import (
    Column, Numeric, Date, String, Text, 
    ForeignKey, Enum as SQLEnum, CheckConstraint
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from .base import BaseModel, GUID


class TransactionType(PyEnum):
    """Types de transactions."""
    BUY = "buy"
    SELL = "sell"
    DIVIDEND = "dividend"
    SPLIT = "split"
    BONUS = "bonus"


class InvestmentTransaction(BaseModel):
    """Modèle transaction d'investissement."""
    
    __tablename__ = "investment_transactions"
    
    # Relations
    investment_id = Column(
        GUID,
        ForeignKey("investments.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        comment="ID de l'investissement"
    )
    
    # Type et date de transaction
    transaction_type = Column(
        SQLEnum(TransactionType),
        nullable=False,
        comment="Type de transaction"
    )
    
    transaction_date = Column(
        Date,
        nullable=False,
        index=True,
        comment="Date de la transaction"
    )
    
    # Détails de la transaction
    quantity = Column(
        Numeric(15, 8),
        nullable=False,
        comment="Quantité de la transaction"
    )
    
    price = Column(
        Numeric(15, 4),
        nullable=False,
        comment="Prix unitaire de la transaction"
    )
    
    total_amount = Column(
        Numeric(15, 2),
        nullable=False,
        comment="Montant total de la transaction"
    )
    
    fees = Column(
        Numeric(10, 2),
        nullable=False,
        default=0,
        comment="Frais de transaction"
    )
    
    # Devise et taux de change
    currency = Column(
        String(3),
        nullable=False,
        default="USD",
        comment="Devise de la transaction (ISO 4217)"
    )
    
    exchange_rate = Column(
        Numeric(10, 6),
        nullable=False,
        default=1.0,
        comment="Taux de change vers la devise de base"
    )
    
    # Notes
    notes = Column(
        Text,
        nullable=True,
        comment="Notes sur la transaction"
    )
    
    # Relations
    investment = relationship(
        "Investment",
        back_populates="transactions",
        lazy="select"
    )
    
    # Contraintes
    __table_args__ = (
        CheckConstraint('quantity != 0', name='chk_non_zero_quantity'),
        CheckConstraint('price > 0', name='chk_positive_price'),
        CheckConstraint('total_amount > 0', name='chk_positive_total_amount'),
        CheckConstraint('fees >= 0', name='chk_non_negative_fees'),
        CheckConstraint('exchange_rate > 0', name='chk_positive_exchange_rate'),
        CheckConstraint('transaction_date <= CURRENT_DATE', name='chk_transaction_date_not_future'),
    )
    
    def __repr__(self) -> str:
        return f"<InvestmentTransaction(id={self.id}, investment_id={self.investment_id}, type='{self.transaction_type}', date='{self.transaction_date}')>"
