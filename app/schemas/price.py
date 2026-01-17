"""
Schémas pour les prix et l'historique des prix.
"""
from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import Field

from .base import BaseSchema

class PriceHistoryItem(BaseSchema):
    """Schéma pour un élément de l'historique des prix."""
    
    price: float = Field(..., description="Prix de clôture")
    market_cap: Optional[int] = Field(None, description="Capitalisation boursière")
    volume: Optional[int] = Field(None, description="Volume d'échanges")
    open_price: Optional[float] = Field(None, description="Prix d'ouverture")
    high_price: Optional[float] = Field(None, description="Prix le plus haut")
    low_price: Optional[float] = Field(None, description="Prix le plus bas")
    close_price: Optional[float] = Field(None, description="Prix de clôture")
    adjusted_close: Optional[float] = Field(None, description="Prix de clôture ajusté")
    dividend_amount: Optional[float] = Field(None, description="Montant du dividende")
    split_ratio: Optional[float] = Field(None, description="Ratio de split")
    timestamp: datetime = Field(..., description="Horodatage des données")
    source: str = Field(..., description="Source des données")


class PriceHistoryResponse(BaseSchema):
    """Schéma de réponse pour l'historique des prix."""
    
    investment_id: UUID = Field(..., description="ID de l'investissement")
    symbol: str = Field(..., description="Symbole de l'investissement")
    price_history: List[PriceHistoryItem] = Field(..., description="Historique des prix")
    total: int = Field(..., description="Nombre total d'entrées")


class PriceUpdateRequest(BaseSchema):
    """Schéma pour une requête de mise à jour des prix."""
    
    investment_ids: Optional[List[UUID]] = Field(None, description="IDs spécifiques d'investissements à mettre à jour")
    force_update: bool = Field(False, description="Forcer la mise à jour même si récente")
    include_historical: bool = Field(False, description="Inclure les données historiques")


class PriceUpdateResponse(BaseSchema):
    """Schéma de réponse pour la mise à jour des prix."""
    
    message: str = Field(..., description="Message de confirmation")
    updated_count: int = Field(..., description="Nombre d'investissements mis à jour")
    errors: List[str] = Field(default_factory=list, description="Erreurs rencontrées")
    updated_investments: List[UUID] = Field(default_factory=list, description="IDs des investissements mis à jour")


class PriceUpdateItem(BaseSchema):
    """Schéma pour un investissement mis à jour."""
    
    investment_id: UUID = Field(..., description="ID de l'investissement")
    symbol: str = Field(..., description="Symbole de l'investissement")
    old_price: Optional[float] = Field(None, description="Ancien prix")
    new_price: float = Field(..., description="Nouveau prix")
    price_change: float = Field(..., description="Variation de prix")
    price_change_percent: float = Field(..., description="Variation de prix en pourcentage")
    timestamp: datetime = Field(..., description="Horodatage de la mise à jour")


class PriceUpdateDetailResponse(BaseSchema):
    """Schéma de réponse détaillée pour la mise à jour d'un prix."""
    
    investment_id: UUID = Field(..., description="ID de l'investissement")
    symbol: str = Field(..., description="Symbole de l'investissement")
    old_price: Optional[float] = Field(None, description="Ancien prix")
    new_price: float = Field(..., description="Nouveau prix")
    price_change: float = Field(..., description="Variation de prix")
    price_change_percent: float = Field(..., description="Variation de prix en pourcentage")
    timestamp: datetime = Field(..., description="Horodatage de la mise à jour")
    source: str = Field(..., description="Source des données")


class MarketData(BaseSchema):
    """Schéma pour les données de marché."""
    
    symbol: str = Field(..., description="Symbole de l'investissement")
    name: str = Field(..., description="Nom de l'investissement")
    current_price: float = Field(..., description="Prix actuel")
    price_change: float = Field(..., description="Variation de prix")
    price_change_percent: float = Field(..., description="Variation de prix en pourcentage")
    volume: Optional[int] = Field(None, description="Volume d'échanges")
    market_cap: Optional[int] = Field(None, description="Capitalisation boursière")
    high_52w: Optional[float] = Field(None, description="Plus haut sur 52 semaines")
    low_52w: Optional[float] = Field(None, description="Plus bas sur 52 semaines")
    pe_ratio: Optional[float] = Field(None, description="Ratio P/E")
    dividend_yield: Optional[float] = Field(None, description="Rendement de dividende")
    currency: str = Field(..., description="Devise")
    exchange: Optional[str] = Field(None, description="Bourse")
    last_updated: datetime = Field(..., description="Dernière mise à jour")


class MarketDataResponse(BaseSchema):
    """Schéma de réponse pour les données de marché."""
    
    data: List[MarketData] = Field(..., description="Données de marché")
    total: int = Field(..., description="Nombre total de données")
    last_updated: datetime = Field(..., description="Dernière mise à jour globale")


class PriceAlert(BaseSchema):
    """Schéma pour une alerte de prix."""
    
    id: UUID = Field(..., description="ID de l'alerte")
    investment_id: UUID = Field(..., description="ID de l'investissement")
    symbol: str = Field(..., description="Symbole de l'investissement")
    target_price: float = Field(..., description="Prix cible")
    alert_type: str = Field(..., description="Type d'alerte (above, below)")
    is_active: bool = Field(..., description="Indique si l'alerte est active")
    created_at: datetime = Field(..., description="Date de création")
    triggered_at: Optional[datetime] = Field(None, description="Date de déclenchement")


class PriceAlertCreate(BaseSchema):
    """Schéma pour créer une alerte de prix."""
    
    investment_id: UUID = Field(..., description="ID de l'investissement")
    target_price: float = Field(..., gt=0, description="Prix cible")
    alert_type: str = Field(..., description="Type d'alerte (above, below)")
    
    def validate_alert_type(cls, v):
        if v not in ["above", "below"]:
            raise ValueError("Le type d'alerte doit être 'above' ou 'below'")
        return v
