"""
Schémas pour le portfolio.
"""
from datetime import datetime
from typing import Dict, List, Optional
from uuid import UUID

from pydantic import Field

from .base import BaseSchema, TimestampSchema, IDSchema


class PortfolioBreakdown(BaseSchema):
    """Schéma pour la répartition du portfolio."""
    
    category: str = Field(..., description="Nom de la catégorie")
    value: str = Field(..., description="Valeur dans cette catégorie")
    percentage: str = Field(..., description="Pourcentage de cette catégorie")
    count: int = Field(..., ge=0, description="Nombre d'investissements dans cette catégorie")


class TopPerformer(BaseSchema):
    """Schéma pour les meilleurs performeurs."""
    
    investment_id: UUID = Field(..., description="ID de l'investissement")
    symbol: str = Field(..., description="Symbole de l'investissement")
    name: str = Field(..., description="Nom de l'investissement")
    gain_loss_percent: str = Field(..., description="Gain/perte en pourcentage")


class PortfolioSummary(IDSchema):
    """Schéma de résumé du portfolio."""
    
    user_id: UUID = Field(..., description="ID de l'utilisateur")
    total_value: str = Field(..., description="Valeur totale du portfolio")
    total_cost: str = Field(..., description="Coût total du portfolio")
    total_gain_loss: str = Field(..., description="Gain/perte total en valeur absolue")
    total_gain_loss_percent: str = Field(..., description="Gain/perte total en pourcentage")
    diversification_score: Optional[str] = Field(None, description="Score de diversification")
    risk_score: Optional[str] = Field(None, description="Score de risque")
    currency: str = Field(..., description="Devise principale")
    investment_count: int = Field(..., ge=0, description="Nombre total d'investissements")
    performance_status: str = Field(..., description="Statut de performance")
    last_updated: datetime = Field(..., description="Dernière mise à jour")
    
    # Répartitions
    breakdown_by_country: Dict[str, PortfolioBreakdown] = Field(default_factory=dict, description="Répartition par pays")
    breakdown_by_sector: Dict[str, PortfolioBreakdown] = Field(default_factory=dict, description="Répartition par secteur")
    breakdown_by_asset_type: Dict[str, PortfolioBreakdown] = Field(default_factory=dict, description="Répartition par type d'actif")
    
    # Performeurs
    top_performers: List[TopPerformer] = Field(default_factory=list, description="Meilleurs performeurs")
    worst_performers: List[TopPerformer] = Field(default_factory=list, description="Pires performeurs")


class DiversificationAnalysis(BaseSchema):
    """Schéma pour l'analyse de diversification."""
    
    overall_score: str = Field(..., description="Score global de diversification")
    recommendations: List[Dict[str, str]] = Field(default_factory=list, description="Recommandations d'amélioration")
    detailed_analysis: Dict[str, Dict[str, str]] = Field(default_factory=dict, description="Analyse détaillée")


class PerformanceAnalysis(BaseSchema):
    """Schéma pour l'analyse de performance."""
    
    period: str = Field(..., description="Période d'analyse")
    portfolio_return: float = Field(..., description="Rendement du portfolio")
    benchmark_return: Optional[float] = Field(None, description="Rendement du benchmark")
    alpha: Optional[float] = Field(None, description="Alpha du portfolio")
    beta: Optional[float] = Field(None, description="Beta du portfolio")
    sharpe_ratio: Optional[float] = Field(None, description="Ratio de Sharpe")
    max_drawdown: Optional[float] = Field(None, description="Perte maximale")
    volatility: Optional[float] = Field(None, description="Volatilité")
    monthly_returns: List[Dict[str, float]] = Field(default_factory=list, description="Rendements mensuels")


class PortfolioSnapshot(BaseSchema):
    """Schéma pour un snapshot de portfolio."""
    
    id: UUID = Field(..., description="ID du snapshot")
    user_id: UUID = Field(..., description="ID de l'utilisateur")
    snapshot_date: str = Field(..., description="Date du snapshot")
    total_value: str = Field(..., description="Valeur totale")
    total_cost: str = Field(..., description="Coût total")
    total_gain_loss: str = Field(..., description="Gain/perte total")
    total_gain_loss_percent: str = Field(..., description="Gain/perte en pourcentage")
    diversification_score: Optional[str] = Field(None, description="Score de diversification")
    risk_score: Optional[str] = Field(None, description="Score de risque")
    currency: str = Field(..., description="Devise")
    investment_count: int = Field(..., description="Nombre d'investissements")
    created_at: datetime = Field(..., description="Date de création")


class PortfolioSnapshotList(BaseSchema):
    """Schéma pour une liste de snapshots de portfolio."""
    
    items: List[PortfolioSnapshot] = Field(..., description="Liste des snapshots")
    total: int = Field(..., description="Nombre total de snapshots")
    limit: int = Field(..., description="Limite appliquée")
    offset: int = Field(..., description="Offset appliqué")


class PortfolioComparison(BaseSchema):
    """Schéma pour la comparaison de portfolios."""
    
    current_portfolio: PortfolioSummary = Field(..., description="Portfolio actuel")
    previous_portfolio: Optional[PortfolioSummary] = Field(None, description="Portfolio précédent")
    changes: Dict[str, Dict[str, str]] = Field(default_factory=dict, description="Changements détectés")
    performance_comparison: Optional[Dict[str, float]] = Field(None, description="Comparaison de performance")
