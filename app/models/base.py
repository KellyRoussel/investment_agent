"""
Modèle de base pour tous les modèles de base de données.
"""
from datetime import datetime
from typing import Any
from uuid import uuid4

from sqlalchemy import Column, DateTime, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import as_declarative, declared_attr


@as_declarative()
class Base:
    """Classe de base pour tous les modèles SQLAlchemy."""
    
    id: Any
    __name__: str
    
    # Générer automatiquement le nom de la table
    @declared_attr
    def __tablename__(cls) -> str:
        return cls.__name__.lower()


class TimestampMixin:
    """Mixin pour ajouter des timestamps automatiques."""
    
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
        comment="Date et heure de création"
    )
    
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
        comment="Date et heure de dernière mise à jour"
    )


class UUIDMixin:
    """Mixin pour ajouter un ID UUID."""
    
    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid4,
        nullable=False,
        comment="Identifiant unique"
    )


class BaseModel(Base, UUIDMixin, TimestampMixin):
    """Modèle de base avec UUID et timestamps."""
    
    __abstract__ = True
