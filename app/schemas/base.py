"""
Schémas de base pour les API.
"""
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class BaseSchema(BaseModel):
    """Schéma de base avec configuration commune."""
    
    class Config:
        """Configuration Pydantic."""
        from_attributes = True
        validate_assignment = True
        arbitrary_types_allowed = True
        json_encoders = {
            datetime: lambda v: v.isoformat(),
            UUID: lambda v: str(v),
        }


class TimestampSchema(BaseSchema):
    """Schéma avec timestamps."""
    
    created_at: datetime = Field(..., description="Date de création")
    updated_at: datetime = Field(..., description="Date de dernière mise à jour")


class IDSchema(BaseSchema):
    """Schéma avec ID."""
    
    id: UUID = Field(..., description="Identifiant unique")


class BaseResponseSchema(BaseSchema):
    """Schéma de base pour les réponses API."""
    
    success: bool = Field(True, description="Indique si la requête a réussi")
    message: Optional[str] = Field(None, description="Message de réponse")


class PaginationSchema(BaseSchema):
    """Schéma pour la pagination."""
    
    page: int = Field(1, ge=1, description="Numéro de page")
    size: int = Field(10, ge=1, le=100, description="Taille de la page")
    total: int = Field(0, ge=0, description="Nombre total d'éléments")
    pages: int = Field(0, ge=0, description="Nombre total de pages")


class PaginatedResponseSchema(BaseResponseSchema):
    """Schéma pour les réponses paginées."""
    
    pagination: PaginationSchema = Field(..., description="Informations de pagination")


class ErrorDetailSchema(BaseSchema):
    """Schéma pour les détails d'erreur."""
    
    field: Optional[str] = Field(None, description="Champ en erreur")
    message: str = Field(..., description="Message d'erreur")
    code: Optional[str] = Field(None, description="Code d'erreur")


class ErrorResponseSchema(BaseSchema):
    """Schéma pour les réponses d'erreur."""
    
    success: bool = Field(False, description="Indique que la requête a échoué")
    error: str = Field(..., description="Type d'erreur")
    message: str = Field(..., description="Message d'erreur")
    details: Optional[list[ErrorDetailSchema]] = Field(None, description="Détails des erreurs")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="Horodatage de l'erreur")
