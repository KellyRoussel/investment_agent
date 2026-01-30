"""
Schémas pour les investissements.
"""
from datetime import date
from typing import Optional, List
from uuid import UUID

from pydantic import Field, field_validator

from app.domain.entities import AssetType, MarketCapCategory
from .base import BaseSchema, TimestampSchema, IDSchema


# Schemas de base
class InvestmentSearchResult(BaseSchema):
    """Résultat de recherche d'investissement."""
    
    symbol: str = Field(..., description="Symbole de l'investissement")
    name: str = Field(..., description="Nom de l'entreprise/actif")
    asset_type: AssetType = Field(..., description="Type d'actif")
    country: str = Field(..., description="Code pays")
    sector: Optional[str] = Field(None, description="Secteur d'activité")
    industry: Optional[str] = Field(None, description="Industrie")
    market_cap: Optional[int] = Field(None, description="Capitalisation boursière")
    currency: str = Field(..., description="Devise")
    exchange: Optional[str] = Field(None, description="Bourse")
    current_price: Optional[float] = Field(None, description="Prix actuel")
    price_change_percent: Optional[float] = Field(None, description="Variation de prix")
    volume: Optional[int] = Field(None, description="Volume d'échanges")
    is_tradable: bool = Field(True, description="Indique si l'investissement est tradable")


class InvestmentSearchResponse(BaseSchema):
    """Réponse de recherche d'investissements."""
    
    results: List[InvestmentSearchResult] = Field(..., description="Résultats de la recherche")
    total: int = Field(..., description="Nombre total de résultats")
    query: str = Field(..., description="Requête de recherche")
    search_time_ms: Optional[int] = Field(None, description="Temps de recherche en millisecondes")


# Schemas de création/modification
class InvestmentCreate(BaseSchema):
    """Schéma pour créer un investissement."""
    
    symbol: str = Field(..., min_length=1, max_length=20, description="Symbole de l'investissement")
    name: str = Field(..., min_length=1, max_length=255, description="Nom de l'entreprise/actif")
    asset_type: AssetType = Field(..., description="Type d'actif")
    country: str = Field(..., min_length=2, max_length=3, description="Code pays ISO 3166-1 alpha-3")
    sector: Optional[str] = Field(None, max_length=100, description="Secteur d'activité")
    industry: Optional[str] = Field(None, max_length=100, description="Industrie")
    market_cap_category: Optional[MarketCapCategory] = Field(None, description="Catégorie de capitalisation")
    purchase_date: date = Field(..., description="Date d'achat")
    purchase_price: float = Field(..., gt=0, description="Prix d'achat unitaire")
    quantity: float = Field(..., gt=0, description="Quantité détenue")
    currency: str = Field(..., min_length=3, max_length=3, description="Devise")
    dividend_yield: Optional[float] = Field(None, ge=0, le=100, description="Rendement de dividende")
    expense_ratio: Optional[float] = Field(None, ge=0, le=10, description="Ratio de frais")
    notes: Optional[str] = Field(None, max_length=1000, description="Notes personnelles")
    
    @field_validator('symbol')
    def validate_symbol(cls, v):
        if not v.replace('-', '').replace('.', '').isalnum():
            raise ValueError('Le symbole ne peut contenir que des lettres, chiffres, tirets et points')
        return v.upper()
    
    @field_validator('country')
    def validate_country(cls, v):
        if not v.isalpha() or not v.isupper():
            raise ValueError('Le code pays doit être un code ISO 3166-1 alpha-3 en majuscules')
        return v
    
    @field_validator('currency')
    def validate_currency(cls, v):
        if not v.isalpha() or not v.isupper():
            raise ValueError('La devise doit être un code ISO 4217 en majuscules')
        return v
    
    @field_validator('purchase_date')
    def validate_purchase_date(cls, v):
        if v > date.today():
            raise ValueError('La date d\'achat ne peut pas être dans le futur')
        return v


class InvestmentUpdate(BaseSchema):
    """Schéma pour mettre à jour un investissement."""
    
    symbol: Optional[str] = Field(None, min_length=1, max_length=20, description="Symbole de l'investissement")
    name: Optional[str] = Field(None, min_length=1, max_length=255, description="Nom de l'entreprise/actif")
    asset_type: Optional[AssetType] = Field(None, description="Type d'actif")
    country: Optional[str] = Field(None, min_length=2, max_length=3, description="Code pays")
    sector: Optional[str] = Field(None, max_length=100, description="Secteur d'activité")
    industry: Optional[str] = Field(None, max_length=100, description="Industrie")
    market_cap_category: Optional[MarketCapCategory] = Field(None, description="Catégorie de capitalisation")
    purchase_date: Optional[date] = Field(None, description="Date d'achat")
    purchase_price: Optional[float] = Field(None, gt=0, description="Prix d'achat unitaire")
    quantity: Optional[float] = Field(None, gt=0, description="Quantité détenue")
    currency: Optional[str] = Field(None, min_length=3, max_length=3, description="Devise")
    dividend_yield: Optional[float] = Field(None, ge=0, le=100, description="Rendement de dividende")
    expense_ratio: Optional[float] = Field(None, ge=0, le=10, description="Ratio de frais")
    notes: Optional[str] = Field(None, max_length=1000, description="Notes personnelles")
    is_active: Optional[bool] = Field(None, description="Indique si l'investissement est actif")
    
    @field_validator('symbol')
    def validate_symbol(cls, v):
        if v is not None:
            if not v.replace('-', '').replace('.', '').isalnum():
                raise ValueError('Le symbole ne peut contenir que des lettres, chiffres, tirets et points')
            return v.upper()
        return v
    
    @field_validator('country')
    def validate_country(cls, v):
        if v is not None:
            if not v.isalpha() or not v.isupper():
                raise ValueError('Le code pays doit être un code ISO 3166-1 alpha-3 en majuscules')
            return v
        return v
    
    @field_validator('currency')
    def validate_currency(cls, v):
        if v is not None:
            if not v.isalpha() or not v.isupper():
                raise ValueError('La devise doit être un code ISO 4217 en majuscules')
            return v
        return v
    
    @field_validator('purchase_date')
    def validate_purchase_date(cls, v):
        if v is not None and v > date.today():
            raise ValueError('La date d\'achat ne peut pas être dans le futur')
        return v


class InvestmentQuantityUpdate(BaseSchema):
    """Schéma pour mettre à jour la quantité d'un investissement."""
    
    quantity: float = Field(..., gt=0, description="Nouvelle quantité")
    price: Optional[float] = Field(None, gt=0, description="Prix pour calculer la moyenne pondérée")
    notes: Optional[str] = Field(None, max_length=500, description="Notes sur la modification")


# Schemas de réponse
class InvestmentResponse(IDSchema, TimestampSchema):
    """Schéma de réponse pour un investissement."""

    user_id: UUID = Field(..., description="ID de l'utilisateur propriétaire")
    symbol: str = Field(..., description="Symbole de l'investissement")
    name: str = Field(..., description="Nom de l'entreprise/actif")
    asset_type: AssetType = Field(..., description="Type d'actif")
    country: str = Field(..., description="Code pays")
    sector: Optional[str] = Field(None, description="Secteur d'activité")
    industry: Optional[str] = Field(None, description="Industrie")
    market_cap_category: Optional[MarketCapCategory] = Field(None, description="Catégorie de capitalisation")
    purchase_date: date = Field(..., description="Date d'achat")
    purchase_price: float = Field(..., description="Prix d'achat unitaire")
    quantity: float = Field(..., description="Quantité détenue")
    currency: str = Field(..., description="Devise")
    dividend_yield: Optional[float] = Field(None, description="Rendement de dividende")
    expense_ratio: Optional[float] = Field(None, description="Ratio de frais")
    notes: Optional[str] = Field(None, description="Notes personnelles")
    is_active: bool = Field(..., description="Indique si l'investissement est actif")


class InvestmentSummary(BaseSchema):
    """Schéma de résumé pour un investissement."""

    id: UUID = Field(..., description="ID de l'investissement")
    symbol: str = Field(..., description="Symbole de l'investissement")
    name: str = Field(..., description="Nom de l'entreprise/actif")
    asset_type: str = Field(..., description="Type d'actif")
    country: str = Field(..., description="Code pays")
    sector: Optional[str] = Field(None, description="Secteur d'activité")
    quantity: float = Field(..., description="Quantité détenue")
    purchase_price: str = Field(..., description="Prix d'achat formaté")
    is_active: bool = Field(..., description="Indique si l'investissement est actif")


class InvestmentListResponse(BaseSchema):
    """Schéma de réponse pour une liste d'investissements."""
    
    items: List[InvestmentSummary] = Field(..., description="Liste des investissements")
    total: int = Field(..., description="Nombre total d'investissements")
    limit: int = Field(..., description="Limite appliquée")
    offset: int = Field(..., description="Offset appliqué")


class InvestmentDeleteResponse(BaseSchema):
    """Schéma de réponse pour la suppression d'un investissement."""
    
    message: str = Field(..., description="Message de confirmation")
    investment_id: UUID = Field(..., description="ID de l'investissement supprimé")
