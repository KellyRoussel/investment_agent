"""
Value Object pour représenter l'argent avec devise.
"""
from decimal import Decimal
from typing import Union
from pydantic import BaseModel, Field, field_validator


class Money(BaseModel):
    """Value Object pour représenter une somme d'argent avec sa devise."""
    
    amount: Decimal = Field(..., decimal_places=4, description="Montant de l'argent")
    currency: str = Field(..., min_length=3, max_length=3, description="Code devise ISO 4217")
    
    @field_validator('amount')
    def validate_amount(cls, v):
        if v < 0:
            raise ValueError('Le montant ne peut pas être négatif')
        return v
    
    @field_validator('currency')
    def validate_currency(cls, v):
        if not v.isalpha() or not v.isupper():
            raise ValueError('La devise doit être un code ISO 4217 en majuscules (ex: USD, EUR)')
        return v
    
    def __add__(self, other: 'Money') -> 'Money':
        if not isinstance(other, Money):
            raise TypeError('Peut seulement additionner avec un autre objet Money')
        if self.currency != other.currency:
            raise ValueError(f'Impossible d\'additionner {self.currency} et {other.currency}')
        return Money(amount=self.amount + other.amount, currency=self.currency)
    
    def __sub__(self, other: 'Money') -> 'Money':
        if not isinstance(other, Money):
            raise TypeError('Peut seulement soustraire avec un autre objet Money')
        if self.currency != other.currency:
            raise ValueError(f'Impossible de soustraire {self.currency} et {other.currency}')
        return Money(amount=self.amount - other.amount, currency=self.currency)
    
    def __mul__(self, multiplier: Union[int, float, Decimal]) -> 'Money':
        if not isinstance(multiplier, (int, float, Decimal)):
            raise TypeError('Le multiplicateur doit être un nombre')
        return Money(amount=self.amount * Decimal(str(multiplier)), currency=self.currency)
    
    def __truediv__(self, divisor: Union[int, float, Decimal]) -> 'Money':
        if not isinstance(divisor, (int, float, Decimal)):
            raise TypeError('Le diviseur doit être un nombre')
        if divisor == 0:
            raise ValueError('Division par zéro')
        return Money(amount=self.amount / Decimal(str(divisor)), currency=self.currency)
    
    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Money):
            return False
        return self.amount == other.amount and self.currency == other.currency
    
    def __lt__(self, other: 'Money') -> bool:
        if not isinstance(other, Money):
            raise TypeError('Peut seulement comparer avec un autre objet Money')
        if self.currency != other.currency:
            raise ValueError(f'Impossible de comparer {self.currency} et {other.currency}')
        return self.amount < other.amount
    
    def __le__(self, other: 'Money') -> bool:
        return self < other or self == other
    
    def __gt__(self, other: 'Money') -> bool:
        return not self <= other
    
    def __ge__(self, other: 'Money') -> bool:
        return not self < other
    
    def to_float(self) -> float:
        """Convertit le montant en float pour les calculs."""
        return float(self.amount)
    
    def round_to_cents(self) -> 'Money':
        """Arrondit le montant au centime le plus proche."""
        return Money(
            amount=self.amount.quantize(Decimal('0.01')),
            currency=self.currency
        )
    
    def format_currency(self, locale: str = 'en_US') -> str:
        """Formate le montant avec la devise pour l'affichage."""
        # Pour une implémentation simple, on utilise un format basique
        # Dans une vraie application, on utiliserait babel ou locale
        currency_symbols = {
            'USD': '$',
            'EUR': '€',
            'GBP': '£',
            'JPY': '¥',
            'CAD': 'C$',
            'CHF': 'CHF',
            'AUD': 'A$',
            'CNY': '¥',
            'SEK': 'kr',
            'NOK': 'kr',
            'DKK': 'kr',
            'PLN': 'zł',
            'CZK': 'Kč',
            'HUF': 'Ft',
            'RUB': '₽',
            'BRL': 'R$',
            'INR': '₹',
            'KRW': '₩',
            'SGD': 'S$',
            'HKD': 'HK$',
            'NZD': 'NZ$',
            'MXN': '$',
            'ZAR': 'R',
            'TRY': '₺',
            'ILS': '₪',
            'AED': 'د.إ',
            'SAR': '﷼',
            'THB': '฿',
            'MYR': 'RM',
            'PHP': '₱',
            'IDR': 'Rp',
            'VND': '₫',
            'TWD': 'NT$',
            'PKR': '₨',
            'BDT': '৳',
            'LKR': '₨',
            'NPR': '₨',
            'MMK': 'K',
            'KHR': '៛',
            'LAK': '₭',
            'BND': 'B$',
            'FJD': 'FJ$',
            'PGK': 'K',
            'SBD': 'SI$',
            'TOP': 'T$',
            'VUV': 'Vt',
            'WST': 'WS$',
            'XOF': 'CFA',
            'XAF': 'FCFA',
            'XPF': '₣'
        }
        
        symbol = currency_symbols.get(self.currency, self.currency)
        
        if self.currency in ['JPY', 'KRW', 'VND', 'IDR']:
            # Devises sans décimales
            return f"{symbol}{self.amount:.0f}"
        else:
            # Devises avec décimales
            return f"{symbol}{self.amount:.2f}"
    
    def __str__(self) -> str:
        return self.format_currency()
    
    def __repr__(self) -> str:
        return f"Money(amount={self.amount}, currency='{self.currency}')"


class MoneyZero(Money):
    """Money avec montant zéro pour une devise donnée."""
    
    def __init__(self, currency: str = "USD"):
        super().__init__(amount=Decimal('0'), currency=currency)


# Constantes utiles
USD_ZERO = MoneyZero("USD")
EUR_ZERO = MoneyZero("EUR")
