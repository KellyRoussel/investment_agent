"""
Service pour calculer les métriques de portfolio à la volée.
"""
from decimal import Decimal
from typing import Dict, List, Optional
from uuid import UUID

from sqlalchemy.orm import Session

from ..domain.entities import Investment, Portfolio
from ..domain.value_objects import Money, Percentage
from ..models.investment import Investment as InvestmentModel


class PortfolioCalculator:
    """Service pour calculer les métriques de portfolio en temps réel."""
    
    def __init__(self, db: Session):
        self.db = db
    
    def calculate_portfolio_metrics(self, user_id: UUID) -> Dict:
        """
        Calcule toutes les métriques du portfolio en temps réel.
        
        Returns:
            Dict contenant toutes les métriques calculées
        """
        # Récupérer tous les investissements actifs
        investments = self.db.query(InvestmentModel).filter(
            InvestmentModel.user_id == user_id,
            InvestmentModel.is_active == True
        ).all()
        
        if not investments:
            return self._empty_portfolio_metrics(user_id)
        
        # Calculer les métriques de base
        total_value = sum(
            inv.current_price * inv.quantity 
            for inv in investments 
            if inv.current_price is not None
        )
        
        total_cost = sum(
            inv.purchase_price * inv.quantity 
            for inv in investments
        )
        
        total_gain_loss = total_value - total_cost
        
        # Calculer le pourcentage de gain/perte
        if total_cost > 0:
            total_gain_loss_percent = (total_gain_loss / total_cost) * 100
        else:
            total_gain_loss_percent = 0
        
        # Calculer les répartitions
        breakdown_by_country = self._calculate_country_breakdown(investments, total_value)
        breakdown_by_sector = self._calculate_sector_breakdown(investments, total_value)
        breakdown_by_asset_type = self._calculate_asset_type_breakdown(investments, total_value)
        
        # Calculer les performeurs
        top_performers, worst_performers = self._calculate_performers(investments)
        
        # Calculer le score de diversification
        diversification_score = self._calculate_diversification_score(
            breakdown_by_country, breakdown_by_sector, breakdown_by_asset_type
        )
        
        return {
            "user_id": user_id,
            "total_value": total_value,
            "total_cost": total_cost,
            "total_gain_loss": total_gain_loss,
            "total_gain_loss_percent": total_gain_loss_percent,
            "diversification_score": diversification_score,
            "investment_count": len(investments),
            "breakdown_by_country": breakdown_by_country,
            "breakdown_by_sector": breakdown_by_sector,
            "breakdown_by_asset_type": breakdown_by_asset_type,
            "top_performers": top_performers,
            "worst_performers": worst_performers,
            "currency": investments[0].currency if investments else "USD"
        }
    
    def _empty_portfolio_metrics(self, user_id: UUID) -> Dict:
        """Retourne des métriques vides pour un portfolio sans investissements."""
        return {
            "user_id": user_id,
            "total_value": 0,
            "total_cost": 0,
            "total_gain_loss": 0,
            "total_gain_loss_percent": 0,
            "diversification_score": 0,
            "investment_count": 0,
            "breakdown_by_country": {},
            "breakdown_by_sector": {},
            "breakdown_by_asset_type": {},
            "top_performers": [],
            "worst_performers": [],
            "currency": "USD"
        }
    
    def _calculate_country_breakdown(self, investments: List[InvestmentModel], total_value: Decimal) -> Dict:
        """Calcule la répartition par pays."""
        country_totals = {}
        country_counts = {}
        
        for inv in investments:
            if inv.current_price is None:
                continue
                
            country = inv.country
            value = inv.current_price * inv.quantity
            
            if country not in country_totals:
                country_totals[country] = 0
                country_counts[country] = 0
            
            country_totals[country] += value
            country_counts[country] += 1
        
        return {
            country: {
                "value": float(total),
                "percentage": float((total / total_value) * 100) if total_value > 0 else 0,
                "count": country_counts[country]
            }
            for country, total in country_totals.items()
        }
    
    def _calculate_sector_breakdown(self, investments: List[InvestmentModel], total_value: Decimal) -> Dict:
        """Calcule la répartition par secteur."""
        sector_totals = {}
        sector_counts = {}
        
        for inv in investments:
            if inv.current_price is None or inv.sector is None:
                continue
                
            sector = inv.sector
            value = inv.current_price * inv.quantity
            
            if sector not in sector_totals:
                sector_totals[sector] = 0
                sector_counts[sector] = 0
            
            sector_totals[sector] += value
            sector_counts[sector] += 1
        
        return {
            sector: {
                "value": float(total),
                "percentage": float((total / total_value) * 100) if total_value > 0 else 0,
                "count": sector_counts[sector]
            }
            for sector, total in sector_totals.items()
        }
    
    def _calculate_asset_type_breakdown(self, investments: List[InvestmentModel], total_value: Decimal) -> Dict:
        """Calcule la répartition par type d'actif."""
        asset_type_totals = {}
        asset_type_counts = {}
        
        for inv in investments:
            if inv.current_price is None:
                continue
                
            asset_type = inv.asset_type.value
            value = inv.current_price * inv.quantity
            
            if asset_type not in asset_type_totals:
                asset_type_totals[asset_type] = 0
                asset_type_counts[asset_type] = 0
            
            asset_type_totals[asset_type] += value
            asset_type_counts[asset_type] += 1
        
        return {
            asset_type: {
                "value": float(total),
                "percentage": float((total / total_value) * 100) if total_value > 0 else 0,
                "count": asset_type_counts[asset_type]
            }
            for asset_type, total in asset_type_totals.items()
        }
    
    def _calculate_performers(self, investments: List[InvestmentModel]) -> tuple:
        """Calcule les meilleurs et pires performeurs."""
        # Filtrer les investissements avec des données de performance
        investments_with_performance = [
            inv for inv in investments
            if inv.current_price is not None and inv.current_price > 0
        ]
        
        # Calculer les performances
        performances = []
        for inv in investments_with_performance:
            cost = inv.purchase_price * inv.quantity
            current_value = inv.current_price * inv.quantity
            
            if cost > 0:
                gain_loss_percent = ((current_value - cost) / cost) * 100
                performances.append({
                    "investment_id": inv.id,
                    "symbol": inv.symbol,
                    "name": inv.name,
                    "gain_loss_percent": gain_loss_percent
                })
        
        # Trier par performance
        performances.sort(key=lambda x: x["gain_loss_percent"], reverse=True)
        
        # Top 3 et bottom 3
        top_performers = performances[:3]
        worst_performers = performances[-3:]
        
        return top_performers, worst_performers
    
    def _calculate_diversification_score(self, country_breakdown: Dict, sector_breakdown: Dict, asset_type_breakdown: Dict) -> float:
        """Calcule le score de diversification basé sur l'indice de Herfindahl."""
        # Calculer l'indice de Herfindahl pour chaque catégorie
        country_herfindahl = sum(
            (breakdown["percentage"] / 100) ** 2 
            for breakdown in country_breakdown.values()
        )
        
        sector_herfindahl = sum(
            (breakdown["percentage"] / 100) ** 2 
            for breakdown in sector_breakdown.values()
        )
        
        asset_type_herfindahl = sum(
            (breakdown["percentage"] / 100) ** 2 
            for breakdown in asset_type_breakdown.values()
        )
        
        # Score de diversification moyen (plus l'indice est bas, plus la diversification est bonne)
        avg_herfindahl = (country_herfindahl + sector_herfindahl + asset_type_herfindahl) / 3
        diversification_score = (1 - avg_herfindahl) * 100
        
        return max(0, diversification_score)
    
    def calculate_investment_metrics(self, investment: InvestmentModel) -> Dict:
        """Calcule les métriques d'un investissement spécifique."""
        if investment.current_price is None:
            return {
                "current_value": None,
                "gain_loss": None,
                "gain_loss_percent": None,
                "performance_status": "unknown"
            }
        
        current_value = investment.current_price * investment.quantity
        total_cost = investment.purchase_price * investment.quantity
        gain_loss = current_value - total_cost
        
        if total_cost > 0:
            gain_loss_percent = (gain_loss / total_cost) * 100
        else:
            gain_loss_percent = 0
        
        # Déterminer le statut de performance
        if gain_loss_percent > 0:
            performance_status = "profitable"
        elif gain_loss_percent < 0:
            performance_status = "losing"
        else:
            performance_status = "neutral"
        
        return {
            "current_value": float(current_value),
            "gain_loss": float(gain_loss),
            "gain_loss_percent": float(gain_loss_percent),
            "performance_status": performance_status
        }
