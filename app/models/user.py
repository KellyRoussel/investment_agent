"""
Modèle de base de données pour les utilisateurs.
"""
from enum import Enum as PyEnum
from typing import List

from sqlalchemy import Column, String, Boolean, Enum as SQLEnum, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from .base import BaseModel, GUID


class RiskTolerance(PyEnum):
    """Niveaux de tolérance au risque."""
    CONSERVATIVE = "conservative"
    MODERATE = "moderate"
    AGGRESSIVE = "aggressive"


class User(BaseModel):
    """Modèle utilisateur."""
    
    __tablename__ = "users"
    
    # Informations de base
    email = Column(
        String(255),
        unique=True,
        nullable=False,
        index=True,
        comment="Adresse email unique de l'utilisateur"
    )
    
    password_hash = Column(
        String(255),
        nullable=False,
        comment="Hash du mot de passe"
    )
    
    full_name = Column(
        String(255),
        nullable=False,
        comment="Nom complet de l'utilisateur"
    )
    
    # Préférences
    currency_preference = Column(
        String(3),
        nullable=False,
        default="USD",
        comment="Devise préférée de l'utilisateur (ISO 4217)"
    )
    
    risk_tolerance = Column(
        SQLEnum(RiskTolerance),
        nullable=False,
        default=RiskTolerance.MODERATE,
        comment="Niveau de tolérance au risque"
    )
    
    # Statut
    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
        comment="Indique si le compte est actif"
    )
    
    email_verified = Column(
        Boolean,
        nullable=False,
        default=False,
        comment="Indique si l'email est vérifié"
    )
    
    # Dernière connexion
    last_login = Column(
        DateTime(timezone=True),
        nullable=True,
        comment="Date et heure de dernière connexion"
    )
    
    # Relations
    investments = relationship(
        "DBInvestment",
        back_populates="user",
        cascade="all, delete-orphan",
        lazy="select"
    )
    
    portfolio_snapshots = relationship(
        "PortfolioSnapshot",
        back_populates="user",
        cascade="all, delete-orphan",
        lazy="select"
    )
    
    def __repr__(self) -> str:
        return f"<User(id={self.id}, email='{self.email}', full_name='{self.full_name}')>"
