"""
Modèle de base pour tous les modèles de base de données.
"""
from datetime import datetime
from typing import Any
from uuid import uuid4

from sqlalchemy import Column, DateTime, func, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import as_declarative, declared_attr
from sqlalchemy.types import TypeDecorator, CHAR
import uuid


class GUID(TypeDecorator):
    """Platform-independent GUID type.
    Uses PostgreSQL's UUID type, otherwise uses CHAR(36), storing as stringified hex values.
    """
    impl = CHAR
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == 'postgresql':
            return dialect.type_descriptor(UUID(as_uuid=True))
        else:
            return dialect.type_descriptor(CHAR(36))

    def process_bind_param(self, value, dialect):
        if value is None:
            return value
        elif dialect.name == 'postgresql':
            return value
        else:
            if not isinstance(value, uuid.UUID):
                return str(uuid.UUID(value))
            else:
                return str(value)

    def process_result_value(self, value, dialect):
        if value is None:
            return value
        else:
            if not isinstance(value, uuid.UUID):
                return uuid.UUID(value)
            else:
                return value


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
        GUID,
        primary_key=True,
        default=uuid4,
        nullable=False,
        comment="Identifiant unique"
    )


class BaseModel(Base, UUIDMixin, TimestampMixin):
    """Modèle de base avec UUID et timestamps."""
    
    __abstract__ = True
