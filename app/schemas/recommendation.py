"""
Schémas pour les recommandations d'investissement.
"""
from datetime import datetime
from decimal import Decimal
from typing import List, Optional, Dict
from uuid import UUID

from pydantic import Field, validator

from app.domain.entities import AssetType
from .base import BaseSchema, TimestampSchema, IDSchema


class InvestmentPreferences(BaseSchema):
    """Schéma pour les préférences d'investissement."""
    
    countries: Optional[List[str]] = Field(None, description="Pays préférés")
    sectors: Optional[List[str]] = Field(None, description="Secteurs préférés")
    exclude_sectors: Optional[List[str]] = Field(None, description="Secteurs à exclure")
    asset_types: Optional[List[AssetType]] = Field(None, description="Types d'actifs préférés")
    min_market_cap: Optional[int] = Field(None, description="Capitalisation minimale")
    max_pe_ratio: Optional[float] = Field(None, description="Ratio P/E maximal")
    min_dividend_yield: Optional[float] = Field(None, description="Rendement de dividende minimal")
    max_expense_ratio: Optional[float] = Field(None, description="Ratio de frais maximal")


class RecommendationRequest(BaseSchema):
    """Schéma pour une requête de recommandation."""
    
    investment_horizon: str = Field(..., description="Horizon d'investissement (short_term, medium_term, long_term)")
    risk_tolerance: str = Field(..., description="Tolérance au risque (conservative, moderate, aggressive)")
    investment_amount: float = Field(..., gt=0, description="Montant à investir")
    currency: str = Field("USD", description="Devise de l'investissement")
    preferences: Optional[InvestmentPreferences] = Field(None, description="Préférences d'investissement")
    objectives: Optional[List[str]] = Field(None, description="Objectifs d'investissement")
    
    @validator('investment_horizon')
    def validate_investment_horizon(cls, v):
        valid_horizons = ["short_term", "medium_term", "long_term"]
        if v not in valid_horizons:
            raise ValueError(f"L'horizon d'investissement doit être l'un de: {', '.join(valid_horizons)}")
        return v
    
    @validator('risk_tolerance')
    def validate_risk_tolerance(cls, v):
        valid_tolerances = ["conservative", "moderate", "aggressive"]
        if v not in valid_tolerances:
            raise ValueError(f"La tolérance au risque doit être l'une de: {', '.join(valid_tolerances)}")
        return v
    
    @validator('currency')
    def validate_currency(cls, v):
        if not v.isalpha() or not v.isupper() or len(v) != 3:
            raise ValueError('La devise doit être un code ISO 4217 en majuscules (ex: USD, EUR)')
        return v


class RecommendationItem(BaseSchema):
    """Schéma pour un élément de recommandation."""
    
    symbol: str = Field(..., description="Symbole de l'investissement")
    name: str = Field(..., description="Nom de l'investissement")
    asset_type: AssetType = Field(..., description="Type d'actif")
    country: str = Field(..., description="Code pays")
    sector: Optional[str] = Field(None, description="Secteur d'activité")
    recommended_amount: float = Field(..., description="Montant recommandé")
    recommended_percentage: float = Field(..., description="Pourcentage recommandé")
    reasoning: str = Field(..., description="Raisonnement de la recommandation")
    risk_score: float = Field(..., ge=0, le=10, description="Score de risque (0-10)")
    expected_return: float = Field(..., description="Rendement attendu")
    confidence_score: float = Field(..., ge=0, le=1, description="Score de confiance (0-1)")
    current_price: Optional[float] = Field(None, description="Prix actuel")
    target_price: Optional[float] = Field(None, description="Prix cible")
    time_horizon: Optional[str] = Field(None, description="Horizon temporel")


class MarketAnalysis(BaseSchema):
    """Schéma pour l'analyse du marché."""
    
    current_market_conditions: str = Field(..., description="Conditions actuelles du marché")
    key_risks: List[str] = Field(default_factory=list, description="Risques clés identifiés")
    opportunities: List[str] = Field(default_factory=list, description="Opportunités identifiées")


class PortfolioImpact(BaseSchema):
    """Schéma pour l'impact sur le portfolio."""
    
    diversification_improvement: float = Field(..., description="Amélioration de la diversification")
    risk_reduction: float = Field(..., description="Réduction du risque")
    expected_return_increase: float = Field(..., description="Augmentation du rendement attendu")


class RecommendationResponse(IDSchema):
    """Schéma de réponse pour une recommandation."""
    
    user_id: UUID = Field(..., description="ID de l'utilisateur")
    recommendation_type: str = Field("portfolio_optimization", description="Type de recommandation")
    investment_horizon: str = Field(..., description="Horizon d'investissement")
    risk_tolerance: str = Field(..., description="Tolérance au risque")
    total_recommended_amount: float = Field(..., description="Montant total recommandé")
    currency: str = Field(..., description="Devise")
    status: str = Field("active", description="Statut de la recommandation")
    confidence_score: Optional[float] = Field(None, description="Score de confiance global")
    generated_by: str = Field("ai_agent", description="Source de génération")
    market_analysis: Optional[MarketAnalysis] = Field(None, description="Analyse du marché")
    portfolio_impact: Optional[PortfolioImpact] = Field(None, description="Impact sur le portfolio")
    reasoning: Optional[str] = Field(None, description="Raisonnement global")
    expires_at: Optional[datetime] = Field(None, description="Date d'expiration")
    recommendations: List[RecommendationItem] = Field(..., description="Liste des recommandations")
    created_at: datetime = Field(..., description="Date de création")
    updated_at: datetime = Field(..., description="Date de dernière mise à jour")


class RecommendationSummary(BaseSchema):
    """Schéma de résumé pour une recommandation."""
    
    id: UUID = Field(..., description="ID de la recommandation")
    investment_horizon: str = Field(..., description="Horizon d'investissement")
    risk_tolerance: str = Field(..., description="Tolérance au risque")
    total_recommended_amount: float = Field(..., description="Montant total recommandé")
    currency: str = Field(..., description="Devise")
    status: str = Field(..., description="Statut de la recommandation")
    recommendations_count: int = Field(..., description="Nombre de recommandations")
    applied_count: int = Field(..., description="Nombre de recommandations appliquées")
    created_at: datetime = Field(..., description="Date de création")


class RecommendationListResponse(BaseSchema):
    """Schéma de réponse pour une liste de recommandations."""
    
    items: List[RecommendationSummary] = Field(..., description="Liste des recommandations")
    total: int = Field(..., description="Nombre total de recommandations")
    limit: int = Field(..., description="Limite appliquée")
    offset: int = Field(..., description="Offset appliqué")


class RecommendationApplyRequest(BaseSchema):
    """Schéma pour appliquer une recommandation."""
    
    applied_investments: List[Dict[str, any]] = Field(..., description="Investissements appliqués")
    notes: Optional[str] = Field(None, description="Notes sur l'application")
    
    @validator('applied_investments')
    def validate_applied_investments(cls, v):
        for item in v:
            if not isinstance(item, dict):
                raise ValueError("Chaque investissement doit être un dictionnaire")
            if 'symbol' not in item or 'applied_amount' not in item:
                raise ValueError("Chaque investissement doit contenir 'symbol' et 'applied_amount'")
        return v


class RecommendationDismissRequest(BaseSchema):
    """Schéma pour rejeter une recommandation."""
    
    reason: str = Field(..., min_length=10, description="Raison du rejet")
    notes: Optional[str] = Field(None, description="Notes supplémentaires")


class RecommendationFeedback(BaseSchema):
    """Schéma pour le feedback sur une recommandation."""
    
    recommendation_id: UUID = Field(..., description="ID de la recommandation")
    rating: int = Field(..., ge=1, le=5, description="Note de 1 à 5")
    feedback: Optional[str] = Field(None, description="Commentaire de feedback")
    was_applied: bool = Field(..., description="Indique si la recommandation a été appliquée")
    applied_amount: Optional[float] = Field(None, description="Montant appliqué si applicable")
