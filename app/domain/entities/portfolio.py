"""
Entité Portfolio du domaine.
"""
from datetime import datetime
from decimal import Decimal
from typing import Dict, List, Optional
from uuid import UUID

from pydantic import BaseModel, Field

from .investment import Investment
from ..value_objects import Money, Percentage


class PortfolioBreakdown(BaseModel):
    """Répartition du portfolio par catégorie."""
    
    category: str = Field(..., description="Nom de la catégorie")
    value: Money = Field(..., description="Valeur dans cette catégorie")
    percentage: Percentage = Field(..., description="Pourcentage de cette catégorie")
    count: int = Field(..., ge=0, description="Nombre d'investissements dans cette catégorie")


class TopPerformer(BaseModel):
    """Meilleur performeur du portfolio."""
    
    investment_id: UUID = Field(..., description="ID de l'investissement")
    symbol: str = Field(..., description="Symbole de l'investissement")
    name: str = Field(..., description="Nom de l'investissement")
    gain_loss_percent: Percentage = Field(..., description="Gain/perte en pourcentage")


class DBPortfolio(BaseModel):
    """Entité Portfolio représentant le portfolio complet d'un utilisateur."""
    
    # Identifiants
    id: UUID = Field(..., description="Identifiant unique du portfolio")
    user_id: UUID = Field(..., description="Identifiant de l'utilisateur propriétaire")
    
    # Investissements
    investments: List[Investment] = Field(default_factory=list, description="Liste des investissements")
    
    # Métriques globales
    total_value: Money = Field(..., description="Valeur totale du portfolio")
    total_cost: Money = Field(..., description="Coût total du portfolio")
    total_gain_loss: Money = Field(..., description="Gain/perte total en valeur absolue")
    total_gain_loss_percent: Percentage = Field(..., description="Gain/perte total en pourcentage")
    
    # Scores d'analyse
    diversification_score: Optional[Percentage] = Field(None, description="Score de diversification (0-100%)")
    risk_score: Optional[Percentage] = Field(None, description="Score de risque (0-100%)")
    
    # Répartitions
    breakdown_by_country: Dict[str, PortfolioBreakdown] = Field(default_factory=dict, description="Répartition par pays")
    breakdown_by_sector: Dict[str, PortfolioBreakdown] = Field(default_factory=dict, description="Répartition par secteur")
    breakdown_by_asset_type: Dict[str, PortfolioBreakdown] = Field(default_factory=dict, description="Répartition par type d'actif")
    
    # Performeurs
    top_performers: List[TopPerformer] = Field(default_factory=list, description="Meilleurs performeurs")
    worst_performers: List[TopPerformer] = Field(default_factory=list, description="Pires performeurs")
    
    # Métadonnées
    currency: str = Field(..., min_length=3, max_length=3, description="Devise principale du portfolio")
    investment_count: int = Field(0, ge=0, description="Nombre total d'investissements")
    last_updated: datetime = Field(default_factory=datetime.utcnow, description="Dernière mise à jour")
    
    def add_investment(self, investment: Investment) -> None:
        """Ajoute un investissement au portfolio."""
        if investment.user_id != self.user_id:
            raise ValueError("L'investissement doit appartenir au même utilisateur")
        
        # Vérifier que l'investissement n'existe pas déjà
        for existing in self.investments:
            if existing.id == investment.id:
                raise ValueError("L'investissement existe déjà dans le portfolio")
        
        self.investments.append(investment)
        self.investment_count += 1
        self._recalculate_metrics()
    
    def remove_investment(self, investment_id: UUID) -> Investment:
        """Retire un investissement du portfolio."""
        for i, investment in enumerate(self.investments):
            if investment.id == investment_id:
                removed_investment = self.investments.pop(i)
                self.investment_count -= 1
                self._recalculate_metrics()
                return removed_investment
        
        raise ValueError(f"Investissement {investment_id} non trouvé dans le portfolio")
    
    def update_investment(self, updated_investment: Investment) -> None:
        """Met à jour un investissement existant dans le portfolio."""
        for i, investment in enumerate(self.investments):
            if investment.id == updated_investment.id:
                self.investments[i] = updated_investment
                self._recalculate_metrics()
                return
        
        raise ValueError(f"Investissement {updated_investment.id} non trouvé dans le portfolio")
    
    def get_investment(self, investment_id: UUID) -> Investment:
        """Récupère un investissement par son ID."""
        for investment in self.investments:
            if investment.id == investment_id:
                return investment
        
        raise ValueError(f"Investissement {investment_id} non trouvé dans le portfolio")
    
    def get_investments_by_type(self, asset_type: str) -> List[Investment]:
        """Récupère tous les investissements d'un type donné."""
        return [inv for inv in self.investments if inv.asset_type.value == asset_type]
    
    def get_investments_by_country(self, country: str) -> List[Investment]:
        """Récupère tous les investissements d'un pays donné."""
        return [inv for inv in self.investments if inv.country == country]
    
    def get_investments_by_sector(self, sector: str) -> List[Investment]:
        """Récupère tous les investissements d'un secteur donné."""
        return [inv for inv in self.investments if inv.sector == sector]
    
    def _recalculate_metrics(self) -> None:
        """Recalcule toutes les métriques du portfolio."""
        active_investments = [inv for inv in self.investments if inv.is_active]
        
        if not active_investments:
            # Portfolio vide
            self.total_value = Money(amount=Decimal('0'), currency=self.currency)
            self.total_cost = Money(amount=Decimal('0'), currency=self.currency)
            self.total_gain_loss = Money(amount=Decimal('0'), currency=self.currency)
            self.total_gain_loss_percent = Percentage(0)
            self._calculate_breakdowns(active_investments)
            self._calculate_performers(active_investments)
            self.last_updated = datetime.utcnow()
            return
        
        # Calculer les totaux
        total_value = sum(
            inv.current_value if inv.current_value else Money(amount=Decimal('0'), currency=self.currency)
            for inv in active_investments
        )
        
        total_cost = sum(
            inv.calculate_total_cost() if inv.is_active else Money(amount=Decimal('0'), currency=self.currency)
            for inv in active_investments
        )
        
        # Calculer le gain/perte
        total_gain_loss = total_value - total_cost
        
        # Calculer le pourcentage de gain/perte
        if total_cost.amount > 0:
            total_gain_loss_percent = Percentage.from_fraction(
                total_gain_loss.amount,
                total_cost.amount
            )
        else:
            total_gain_loss_percent = Percentage(0)
        
        # Mettre à jour les métriques
        self.total_value = total_value
        self.total_cost = total_cost
        self.total_gain_loss = total_gain_loss
        self.total_gain_loss_percent = total_gain_loss_percent
        
        # Calculer les répartitions
        self._calculate_breakdowns(active_investments)
        
        # Calculer les performeurs
        self._calculate_performers(active_investments)
        
        # Calculer le score de diversification
        self._calculate_diversification_score()
        
        self.last_updated = datetime.utcnow()
    
    def _calculate_breakdowns(self, investments: List[Investment]) -> None:
        """Calcule les répartitions du portfolio."""
        if not investments:
            self.breakdown_by_country = {}
            self.breakdown_by_sector = {}
            self.breakdown_by_asset_type = {}
            return
        
        # Répartition par pays
        country_totals = {}
        country_counts = {}
        for inv in investments:
            if inv.current_value:
                country = inv.country
                if country not in country_totals:
                    country_totals[country] = Money(amount=Decimal('0'), currency=self.currency)
                    country_counts[country] = 0
                
                country_totals[country] = country_totals[country] + inv.current_value
                country_counts[country] += 1
        
        self.breakdown_by_country = {
            country: PortfolioBreakdown(
                category=country,
                value=total,
                percentage=Percentage.from_fraction(total.amount, self.total_value.amount) if self.total_value.amount > 0 else Percentage(0),
                count=country_counts[country]
            )
            for country, total in country_totals.items()
        }
        
        # Répartition par secteur
        sector_totals = {}
        sector_counts = {}
        for inv in investments:
            if inv.current_value and inv.sector:
                sector = inv.sector
                if sector not in sector_totals:
                    sector_totals[sector] = Money(amount=Decimal('0'), currency=self.currency)
                    sector_counts[sector] = 0
                
                sector_totals[sector] = sector_totals[sector] + inv.current_value
                sector_counts[sector] += 1
        
        self.breakdown_by_sector = {
            sector: PortfolioBreakdown(
                category=sector,
                value=total,
                percentage=Percentage.from_fraction(total.amount, self.total_value.amount) if self.total_value.amount > 0 else Percentage(0),
                count=sector_counts[sector]
            )
            for sector, total in sector_totals.items()
        }
        
        # Répartition par type d'actif
        asset_type_totals = {}
        asset_type_counts = {}
        for inv in investments:
            if inv.current_value:
                asset_type = inv.asset_type.value
                if asset_type not in asset_type_totals:
                    asset_type_totals[asset_type] = Money(amount=Decimal('0'), currency=self.currency)
                    asset_type_counts[asset_type] = 0
                
                asset_type_totals[asset_type] = asset_type_totals[asset_type] + inv.current_value
                asset_type_counts[asset_type] += 1
        
        self.breakdown_by_asset_type = {
            asset_type: PortfolioBreakdown(
                category=asset_type,
                value=total,
                percentage=Percentage.from_fraction(total.amount, self.total_value.amount) if self.total_value.amount > 0 else Percentage(0),
                count=asset_type_counts[asset_type]
            )
            for asset_type, total in asset_type_totals.items()
        }
    
    def _calculate_performers(self, investments: List[Investment]) -> None:
        """Calcule les meilleurs et pires performeurs."""
        # Filtrer les investissements avec des données de performance
        investments_with_performance = [
            inv for inv in investments
            if inv.gain_loss_percent is not None and inv.current_value and inv.current_value.amount > 0
        ]
        
        # Trier par performance
        sorted_by_performance = sorted(
            investments_with_performance,
            key=lambda inv: inv.gain_loss_percent.value,
            reverse=True
        )
        
        # Meilleurs performeurs (top 3)
        self.top_performers = [
            TopPerformer(
                investment_id=inv.id,
                symbol=inv.symbol,
                name=inv.name,
                gain_loss_percent=inv.gain_loss_percent
            )
            for inv in sorted_by_performance[:3]
        ]
        
        # Pires performeurs (bottom 3)
        self.worst_performers = [
            TopPerformer(
                investment_id=inv.id,
                symbol=inv.symbol,
                name=inv.name,
                gain_loss_percent=inv.gain_loss_percent
            )
            for inv in sorted_by_performance[-3:]
        ]
    
    def _calculate_diversification_score(self) -> None:
        """Calcule le score de diversification basé sur l'indice de Herfindahl."""
        if not self.investments:
            self.diversification_score = Percentage(0)
            return
        
        # Calculer l'indice de Herfindahl pour les pays
        country_herfindahl = 0
        if self.breakdown_by_country:
            for breakdown in self.breakdown_by_country.values():
                country_herfindahl += breakdown.percentage.to_decimal() ** 2
        
        # Calculer l'indice de Herfindahl pour les secteurs
        sector_herfindahl = 0
        if self.breakdown_by_sector:
            for breakdown in self.breakdown_by_sector.values():
                sector_herfindahl += breakdown.percentage.to_decimal() ** 2
        
        # Calculer l'indice de Herfindahl pour les types d'actifs
        asset_type_herfindahl = 0
        if self.breakdown_by_asset_type:
            for breakdown in self.breakdown_by_asset_type.values():
                asset_type_herfindahl += breakdown.percentage.to_decimal() ** 2
        
        # Score de diversification moyen (plus l'indice est bas, plus la diversification est bonne)
        # Convertir en score de 0-100% (plus c'est élevé, mieux c'est)
        avg_herfindahl = (country_herfindahl + sector_herfindahl + asset_type_herfindahl) / 3
        diversification_score = (1 - avg_herfindahl) * 100
        
        self.diversification_score = Percentage(max(0, diversification_score))
    
    def is_profitable(self) -> bool:
        """Retourne True si le portfolio est profitable."""
        return self.total_gain_loss.amount > 0
    
    def is_losing(self) -> bool:
        """Retourne True si le portfolio est en perte."""
        return self.total_gain_loss.amount < 0
    
    def get_performance_status(self) -> str:
        """Retourne le statut de performance du portfolio."""
        if self.total_gain_loss_percent.is_positive():
            return "profitable"
        elif self.total_gain_loss_percent.is_negative():
            return "losing"
        else:
            return "neutral"
    
    def to_summary_dict(self) -> dict:
        """Retourne un résumé du portfolio sous forme de dictionnaire."""
        return {
            "id": str(self.id),
            "user_id": str(self.user_id),
            "total_value": self.total_value.format_currency(),
            "total_cost": self.total_cost.format_currency(),
            "total_gain_loss": self.total_gain_loss.format_currency(),
            "total_gain_loss_percent": str(self.total_gain_loss_percent),
            "diversification_score": str(self.diversification_score) if self.diversification_score else None,
            "risk_score": str(self.risk_score) if self.risk_score else None,
            "currency": self.currency,
            "investment_count": self.investment_count,
            "performance_status": self.get_performance_status(),
            "last_updated": self.last_updated.isoformat(),
            "breakdown_by_country": {
                country: {
                    "value": breakdown.value.format_currency(),
                    "percentage": str(breakdown.percentage),
                    "count": breakdown.count
                }
                for country, breakdown in self.breakdown_by_country.items()
            },
            "breakdown_by_sector": {
                sector: {
                    "value": breakdown.value.format_currency(),
                    "percentage": str(breakdown.percentage),
                    "count": breakdown.count
                }
                for sector, breakdown in self.breakdown_by_sector.items()
            },
            "breakdown_by_asset_type": {
                asset_type: {
                    "value": breakdown.value.format_currency(),
                    "percentage": str(breakdown.percentage),
                    "count": breakdown.count
                }
                for asset_type, breakdown in self.breakdown_by_asset_type.items()
            },
            "top_performers": [
                {
                    "investment_id": str(performer.investment_id),
                    "symbol": performer.symbol,
                    "name": performer.name,
                    "gain_loss_percent": str(performer.gain_loss_percent)
                }
                for performer in self.top_performers
            ],
            "worst_performers": [
                {
                    "investment_id": str(performer.investment_id),
                    "symbol": performer.symbol,
                    "name": performer.name,
                    "gain_loss_percent": str(performer.gain_loss_percent)
                }
                for performer in self.worst_performers
            ]
        }
    
    class Config:
        """Configuration Pydantic."""
        validate_assignment = True
        arbitrary_types_allowed = True
