"""
Value Object pour représenter un pourcentage.
"""
from decimal import Decimal
from typing import Union
from pydantic import BaseModel, Field, validator


class Percentage(BaseModel):
    """Value Object pour représenter un pourcentage."""
    
    value: Decimal = Field(..., decimal_places=4, description="Valeur du pourcentage")
    
    @validator('value')
    def validate_value(cls, v):
        if v < -100:
            raise ValueError('Un pourcentage ne peut pas être inférieur à -100%')
        return v
    
    def __init__(self, value: Union[int, float, Decimal, str], **data):
        # Convertir en Decimal si nécessaire
        if isinstance(value, str):
            # Supprimer le symbole % s'il est présent
            value = value.replace('%', '')
        decimal_value = Decimal(str(value))
        super().__init__(value=decimal_value, **data)
    
    @classmethod
    def from_decimal(cls, value: Decimal) -> 'Percentage':
        """Crée un pourcentage à partir d'un Decimal."""
        return cls(value=value)
    
    @classmethod
    def from_fraction(cls, numerator: Union[int, float, Decimal], denominator: Union[int, float, Decimal]) -> 'Percentage':
        """Crée un pourcentage à partir d'une fraction."""
        if denominator == 0:
            raise ValueError('Le dénominateur ne peut pas être zéro')
        decimal_value = (Decimal(str(numerator)) / Decimal(str(denominator))) * 100
        return cls(value=decimal_value)
    
    @classmethod
    def from_ratio(cls, ratio: Union[int, float, Decimal]) -> 'Percentage':
        """Crée un pourcentage à partir d'un ratio (0.1 = 10%)."""
        return cls(value=Decimal(str(ratio)) * 100)
    
    def __add__(self, other: 'Percentage') -> 'Percentage':
        if not isinstance(other, Percentage):
            raise TypeError('Peut seulement additionner avec un autre objet Percentage')
        return Percentage(value=self.value + other.value)
    
    def __sub__(self, other: 'Percentage') -> 'Percentage':
        if not isinstance(other, Percentage):
            raise TypeError('Peut seulement soustraire avec un autre objet Percentage')
        return Percentage(value=self.value - other.value)
    
    def __mul__(self, multiplier: Union[int, float, Decimal]) -> 'Percentage':
        if not isinstance(multiplier, (int, float, Decimal)):
            raise TypeError('Le multiplicateur doit être un nombre')
        return Percentage(value=self.value * Decimal(str(multiplier)))
    
    def __truediv__(self, divisor: Union[int, float, Decimal]) -> 'Percentage':
        if not isinstance(divisor, (int, float, Decimal)):
            raise TypeError('Le diviseur doit être un nombre')
        if divisor == 0:
            raise ValueError('Division par zéro')
        return Percentage(value=self.value / Decimal(str(divisor)))
    
    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Percentage):
            return False
        return self.value == other.value
    
    def __lt__(self, other: 'Percentage') -> bool:
        if not isinstance(other, Percentage):
            raise TypeError('Peut seulement comparer avec un autre objet Percentage')
        return self.value < other.value
    
    def __le__(self, other: 'Percentage') -> bool:
        return self < other or self == other
    
    def __gt__(self, other: 'Percentage') -> bool:
        return not self <= other
    
    def __ge__(self, other: 'Percentage') -> bool:
        return not self < other
    
    def to_decimal(self) -> Decimal:
        """Convertit le pourcentage en decimal (10% = 0.1)."""
        return self.value / 100
    
    def to_fraction(self) -> Decimal:
        """Convertit le pourcentage en fraction (10% = 10/100)."""
        return self.value / 100
    
    def to_float(self) -> float:
        """Convertit le pourcentage en float."""
        return float(self.value)
    
    def is_positive(self) -> bool:
        """Retourne True si le pourcentage est positif."""
        return self.value > 0
    
    def is_negative(self) -> bool:
        """Retourne True si le pourcentage est négatif."""
        return self.value < 0
    
    def is_zero(self) -> bool:
        """Retourne True si le pourcentage est zéro."""
        return self.value == 0
    
    def abs(self) -> 'Percentage':
        """Retourne la valeur absolue du pourcentage."""
        return Percentage(value=abs(self.value))
    
    def format_percentage(self, decimal_places: int = 2) -> str:
        """Formate le pourcentage pour l'affichage."""
        return f"{self.value:.{decimal_places}f}%"
    
    def format_percentage_with_sign(self, decimal_places: int = 2) -> str:
        """Formate le pourcentage avec le signe pour l'affichage."""
        if self.value > 0:
            return f"+{self.value:.{decimal_places}f}%"
        else:
            return f"{self.value:.{decimal_places}f}%"
    
    def __str__(self) -> str:
        return self.format_percentage()
    
    def __repr__(self) -> str:
        return f"Percentage(value={self.value})"


# Constantes utiles
ZERO_PERCENT = Percentage(0)
HUNDRED_PERCENT = Percentage(100)
