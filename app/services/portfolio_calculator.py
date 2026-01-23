"""
Service pour calculer les métriques de portfolio à la volée.
"""
from datetime import date
from decimal import Decimal
from typing import Dict, List, Optional
from uuid import UUID

from sqlalchemy.orm import Session

from app.models.investment import DBInvestment as InvestmentModel
from app.models.user import User
from app.services.currency_converter import CurrencyConverter


class PortfolioCalculator:
    """Service pour calculer les métriques de portfolio en temps réel."""
    
    def __init__(self, db: Session):
        self.db = db
    
    def calculate_portfolio_metrics(self, user_id: UUID, user_currency: str = "USD") -> Dict:
        """
        Calcule toutes les métriques du portfolio en temps réel.
        All values are converted to the user's preferred currency.

        Args:
            user_id: User ID
            user_currency: User's preferred currency (default: USD)

        Returns:
            Dict contenant toutes les métriques calculées
        """
        # Récupérer tous les investissements actifs
        investments = self.db.query(InvestmentModel).filter(
            InvestmentModel.user_id == user_id,
            InvestmentModel.is_active == True
        ).all()

        if not investments:
            return self._empty_portfolio_metrics(user_id, user_currency)

        # Calculer les métriques de base avec conversion de devise
        total_value = Decimal(0)
        total_cost = Decimal(0)

        for inv in investments:
            if inv.current_price is not None:
                # Convert current value to user's currency
                current_value_original = inv.current_price * inv.quantity
                rate = CurrencyConverter.get_exchange_rate(
                    inv.currency,
                    user_currency,
                    date.today()
                )
                if rate:
                    total_value += current_value_original * Decimal(str(rate))
                else:
                    # Fallback: use original currency value
                    total_value += current_value_original

            # Convert purchase cost to user's currency
            cost_original = inv.purchase_price * inv.quantity
            rate = CurrencyConverter.get_exchange_rate(
                inv.currency,
                user_currency,
                inv.purchase_date
            )
            if rate:
                total_cost += cost_original * Decimal(str(rate))
            else:
                # Fallback: use original currency value
                total_cost += cost_original

        total_gain_loss = total_value - total_cost

        # Calculer le pourcentage de gain/perte
        if total_cost > 0:
            total_gain_loss_percent = (total_gain_loss / total_cost) * 100
        else:
            total_gain_loss_percent = 0

        # Calculer les répartitions (with currency conversion)
        breakdown_by_country = self._calculate_country_breakdown(investments, total_value, user_currency)
        breakdown_by_sector = self._calculate_sector_breakdown(investments, total_value, user_currency)
        breakdown_by_asset_type = self._calculate_asset_type_breakdown(investments, total_value, user_currency)

        # Calculer les performeurs (with currency conversion)
        top_performers, worst_performers = self._calculate_performers(investments, user_currency)

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
            "currency": user_currency
        }
    
    def _empty_portfolio_metrics(self, user_id: UUID, user_currency: str = "USD") -> Dict:
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
            "currency": user_currency
        }
    
    def _calculate_country_breakdown(self, investments: List[InvestmentModel], total_value: Decimal, user_currency: str) -> Dict:
        """Calcule la répartition par pays avec conversion de devise."""
        country_totals = {}
        country_counts = {}

        for inv in investments:
            if inv.current_price is None:
                continue

            country = inv.country
            value_original = inv.current_price * inv.quantity

            # Convert to user's currency
            rate = CurrencyConverter.get_exchange_rate(inv.currency, user_currency, date.today())
            value = value_original * Decimal(str(rate)) if rate else value_original

            if country not in country_totals:
                country_totals[country] = Decimal(0)
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
    
    def _calculate_sector_breakdown(self, investments: List[InvestmentModel], total_value: Decimal, user_currency: str) -> Dict:
        """Calcule la répartition par secteur avec conversion de devise."""
        sector_totals = {}
        sector_counts = {}

        for inv in investments:
            if inv.current_price is None or inv.sector is None:
                continue

            sector = inv.sector
            value_original = inv.current_price * inv.quantity

            # Convert to user's currency
            rate = CurrencyConverter.get_exchange_rate(inv.currency, user_currency, date.today())
            value = value_original * Decimal(str(rate)) if rate else value_original

            if sector not in sector_totals:
                sector_totals[sector] = Decimal(0)
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
    
    def _calculate_asset_type_breakdown(self, investments: List[InvestmentModel], total_value: Decimal, user_currency: str) -> Dict:
        """Calcule la répartition par type d'actif avec conversion de devise."""
        asset_type_totals = {}
        asset_type_counts = {}

        for inv in investments:
            if inv.current_price is None:
                continue

            asset_type = inv.asset_type.value
            value_original = inv.current_price * inv.quantity

            # Convert to user's currency
            rate = CurrencyConverter.get_exchange_rate(inv.currency, user_currency, date.today())
            value = value_original * Decimal(str(rate)) if rate else value_original

            if asset_type not in asset_type_totals:
                asset_type_totals[asset_type] = Decimal(0)
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
    
    def _calculate_performers(self, investments: List[InvestmentModel], user_currency: str) -> tuple:
        """Calcule les meilleurs et pires performeurs avec conversion de devise."""
        # Filtrer les investissements avec des données de performance
        investments_with_performance = [
            inv for inv in investments
            if inv.current_price is not None and inv.current_price > 0
        ]

        # Calculer les performances
        performances = []
        for inv in investments_with_performance:
            cost_original = inv.purchase_price * inv.quantity
            current_value_original = inv.current_price * inv.quantity

            # Convert to user's currency
            cost_rate = CurrencyConverter.get_exchange_rate(inv.currency, user_currency, inv.purchase_date)
            current_rate = CurrencyConverter.get_exchange_rate(inv.currency, user_currency, date.today())

            cost = cost_original * Decimal(str(cost_rate)) if cost_rate else cost_original
            current_value = current_value_original * Decimal(str(current_rate)) if current_rate else current_value_original

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
    
    def calculate_investment_metrics(self, investment: InvestmentModel, user_currency: str = None) -> Dict:
        """
        Calcule les métriques d'un investissement spécifique.

        Args:
            investment: Investment model
            user_currency: Target currency for conversion (if None, uses investment's original currency)
        """
        print("Calculating metrics for investment:", investment.id)
        if investment.current_price is None:
            return {
                "current_value": None,
                "gain_loss": None,
                "gain_loss_percent": None,
                "performance_status": "unknown"
            }

        current_value = investment.current_price * investment.quantity
        total_cost = investment.purchase_price * investment.quantity

        # Convert to user's currency if specified
        if user_currency and user_currency != investment.currency:
            # Convert current value
            current_rate = CurrencyConverter.get_exchange_rate(
                investment.currency,
                user_currency,
                date.today()
            )
            if current_rate:
                current_value = current_value * Decimal(str(current_rate))

            # Convert cost
            cost_rate = CurrencyConverter.get_exchange_rate(
                investment.currency,
                user_currency,
                investment.purchase_date
            )
            if cost_rate:
                total_cost = total_cost * Decimal(str(cost_rate))

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
