"""
Entité Investment du domaine.
"""
from datetime import date, datetime
from decimal import Decimal
from enum import Enum
from typing import Optional, List
from uuid import UUID, uuid4

from pydantic import BaseModel, Field, field_validator

from ..value_objects import Money, Percentage


class AssetType(str, Enum):
    """Types d'actifs supportés."""
    STOCK = "stock"
    ETF = "etf"
    CRYPTO = "crypto"
    BOND = "bond"
    COMMODITY = "commodity"
    REIT = "reit"
    MUTUAL_FUND = "mutual_fund"


class MarketCapCategory(str, Enum):
    """Catégories de capitalisation boursière."""
    LARGE_CAP = "large_cap"      # > $10B
    MID_CAP = "mid_cap"          # $2B - $10B
    SMALL_CAP = "small_cap"      # $300M - $2B
    MICRO_CAP = "micro_cap"      # < $300M

class Vehicle(BaseModel):
    # Informations de base
    symbol: str = Field(..., min_length=1, max_length=20, description="Symbole de l'investissement")
    name: str = Field(..., min_length=1, max_length=255, description="Nom de l'entreprise/actif")
    
    # Classification
    asset_type: AssetType = Field(..., description="Type d'actif")
    country: str = Field(..., min_length=2, max_length=3, description="Code pays ISO 3166-1 alpha-3")
    sector: Optional[str] = Field(None, max_length=100, description="Secteur d'activité")
    industry: Optional[str] = Field(None, max_length=100, description="Industrie spécifique")
    market_cap_category: Optional[MarketCapCategory] = Field(None, description="Catégorie de capitalisation")
    
    # Prix et valeur actuels
    current_price: Optional[Money] = Field(None, description="Prix actuel unitaire")
    current_value: Optional[Money] = Field(None, description="Valeur actuelle totale")
    

    @field_validator('symbol')
    def validate_symbol(cls, v):
        # Validation basique du symbole
        if not v.replace('-', '').replace('.', '').isalnum():
            raise ValueError('Le symbole ne peut contenir que des lettres, chiffres, tirets et points')
        return v.upper()
    
    @field_validator('country')
    def validate_country(cls, v):
        if not v.isalpha() or not v.isupper():
            raise ValueError('Le code pays doit être un code ISO 3166-1 alpha-3 en majuscules')
        return v
    
   



class Investment(BaseModel):
    """Entité Investment représentant un investissement dans le portfolio."""
    
    # Identifiants
    id: UUID = Field(default_factory=uuid4, description="Identifiant unique de l'investissement")
    user_id: UUID = Field(..., description="Identifiant de l'utilisateur propriétaire")

    vehicle: Vehicle = Field(..., description="Détails de l'investissement")

    
    # Informations d'achat
    purchase_date: date = Field(..., description="Date d'achat")
    purchase_price: Money = Field(..., description="Prix d'achat unitaire")
    quantity: int = Field(..., gt=0, description="Quantité détenue")

    @field_validator('purchase_date')
    def validate_purchase_date(cls, v):
        if v > date.today():
            raise ValueError('La date d\'achat ne peut pas être dans le futur')
        return v
    
    def update_current_price(self, new_price: Money) -> None:
        """Met à jour le prix actuel et recalcule les valeurs dérivées."""
        if new_price.currency != self.purchase_price.currency:
            raise ValueError(f'Le prix actuel ({new_price.currency}) doit avoir la même devise que le prix d\'achat ({self.purchase_price.currency})')
        
        self.current_price = new_price
        self.current_value = new_price * self.quantity
        
        # Calculer le gain/perte
        total_purchase_value = self.purchase_price * self.quantity
        self.gain_loss = self.current_value - total_purchase_value
        
        # Calculer le pourcentage de gain/perte
        if total_purchase_value.amount > 0:
            self.gain_loss_percent = Percentage.from_fraction(
                self.gain_loss.amount,
                total_purchase_value.amount
            )
        else:
            self.gain_loss_percent = Percentage(0)
        
        self.updated_at = datetime.utcnow()
    
    def add_quantity(self, additional_quantity: Decimal, new_price: Money) -> None:
        """Ajoute de la quantité à l'investissement (moyenne pondérée)."""
        if additional_quantity <= 0:
            raise ValueError('La quantité à ajouter doit être positive')
        
        if new_price.currency != self.purchase_price.currency:
            raise ValueError(f'Le nouveau prix ({new_price.currency}) doit avoir la même devise que le prix d\'achat ({self.purchase_price.currency})')
        
        # Calculer le nouveau prix d'achat moyen pondéré
        total_current_value = self.purchase_price * self.quantity
        additional_value = new_price * additional_quantity
        total_new_quantity = self.quantity + additional_quantity
        
        # Nouveau prix moyen pondéré
        self.purchase_price = Money(
            amount=(total_current_value.amount + additional_value.amount) / total_new_quantity,
            currency=self.purchase_price.currency
        )
        
        # Mettre à jour la quantité
        self.quantity = total_new_quantity
        
        # Mettre à jour le prix actuel si défini
        if self.current_price:
            self.update_current_price(self.current_price)
        
        self.updated_at = datetime.utcnow()
    
    def remove_quantity(self, quantity_to_remove: Decimal) -> Decimal:
        """Retire de la quantité de l'investissement."""
        if quantity_to_remove <= 0:
            raise ValueError('La quantité à retirer doit être positive')
        
        if quantity_to_remove > self.quantity:
            raise ValueError('La quantité à retirer ne peut pas dépasser la quantité détenue')
        
        # Calculer la quantité restante
        remaining_quantity = self.quantity - quantity_to_remove
        
        # Si on retire tout, marquer comme inactif
        if remaining_quantity == 0:
            self.is_active = False
        
        self.quantity = remaining_quantity
        self.updated_at = datetime.utcnow()
        
        return remaining_quantity
    
    def calculate_total_cost(self) -> Money:
        """Calcule le coût total de l'investissement."""
        return self.purchase_price * self.quantity
    
    def is_profitable(self) -> bool:
        """Retourne True si l'investissement est profitable."""
        if not self.gain_loss:
            return False
        return self.gain_loss.amount > 0
    
    def is_losing(self) -> bool:
        """Retourne True si l'investissement est en perte."""
        if not self.gain_loss:
            return False
        return self.gain_loss.amount < 0
    
    def get_performance_status(self) -> str:
        """Retourne le statut de performance de l'investissement."""
        if not self.gain_loss_percent:
            return "unknown"
        
        if self.gain_loss_percent.is_positive():
            return "profitable"
        elif self.gain_loss_percent.is_negative():
            return "losing"
        else:
            return "neutral"
    
    def to_summary_dict(self) -> dict:
        """Retourne un résumé de l'investissement sous forme de dictionnaire."""
        return {
            "id": str(self.id),
            "symbol": self.symbol,
            "name": self.name,
            "asset_type": self.asset_type.value,
            "country": self.country,
            "sector": self.sector,
            "quantity": float(self.quantity),
            "purchase_price": self.purchase_price.format_currency(),
            "current_price": self.current_price.format_currency() if self.current_price else None,
            "current_value": self.current_value.format_currency() if self.current_value else None,
            "gain_loss": self.gain_loss.format_currency() if self.gain_loss else None,
            "gain_loss_percent": str(self.gain_loss_percent) if self.gain_loss_percent else None,
            "performance_status": self.get_performance_status(),
            "is_active": self.is_active
        }
    
    class Config:
        """Configuration Pydantic."""
        use_enum_values = True
        validate_assignment = True
        arbitrary_types_allowed = True
    
    
    