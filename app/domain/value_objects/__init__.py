"""
Value Objects du domaine.
"""
from .money import Money, MoneyZero, USD_ZERO, EUR_ZERO
from .percentage import Percentage, ZERO_PERCENT, HUNDRED_PERCENT

__all__ = [
    'Money',
    'MoneyZero', 
    'USD_ZERO',
    'EUR_ZERO',
    'Percentage',
    'ZERO_PERCENT',
    'HUNDRED_PERCENT',
]
