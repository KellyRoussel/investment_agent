"""
Investment Portfolio Agent - Demo Script

This script demonstrates:
1. Creating database tables
2. Adding users and investments to the database
3. Querying data using repositories
4. Running portfolio calculations using the PortfolioCalculator service
"""
from datetime import date
from decimal import Decimal
import json
import sys
from pathlib import Path

# Add app directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from database import create_tables, SessionLocal
from models.user import RiskTolerance
from models.investment import AssetType, MarketCapCategory
from repositories import UserRepository, InvestmentRepository
from services.portfolio_calculator import PortfolioCalculator


def print_section(title: str):
    """Print a formatted section header."""
    print(f"\n{'=' * 80}")
    print(f"  {title}")
    print(f"{'=' * 80}\n")


def print_investment(inv):
    """Print investment details."""
    print(f"  - {inv.symbol} ({inv.name})")
    print(f"    Type: {inv.asset_type.value}, Country: {inv.country}")
    print(f"    Quantity: {inv.quantity}, Purchase Price: ${inv.purchase_price}")
    if inv.current_price:
        print(f"    Current Price: ${inv.current_price}")
        print(f"    Current Value: ${inv.current_value:.2f}")
        print(f"    Gain/Loss: ${inv.gain_loss:.2f} ({inv.gain_loss_percent:.2f}%)")
    print()


def print_metrics(metrics: dict):
    """Print portfolio metrics in a formatted way."""
    print(f"  Investment Count: {metrics['investment_count']}")
    print(f"  Total Cost: ${metrics['total_cost']:,.2f}")
    print(f"  Total Value: ${metrics['total_value']:,.2f}")
    print(f"  Total Gain/Loss: ${metrics['total_gain_loss']:,.2f} ({metrics['total_gain_loss_percent']:.2f}%)")
    print(f"  Diversification Score: {metrics['diversification_score']:.2f}/100")
    print()
    
    # Asset Type Breakdown
    if metrics['breakdown_by_asset_type']:
        print("  Asset Type Breakdown:")
        for asset_type, data in metrics['breakdown_by_asset_type'].items():
            print(f"    {asset_type}: ${data['value']:,.2f} ({data['percentage']:.1f}%) - {data['count']} investments")
        print()
    
    # Country Breakdown
    if metrics['breakdown_by_country']:
        print("  Country Breakdown:")
        for country, data in metrics['breakdown_by_country'].items():
            print(f"    {country}: ${data['value']:,.2f} ({data['percentage']:.1f}%) - {data['count']} investments")
        print()
    
    # Sector Breakdown
    if metrics['breakdown_by_sector']:
        print("  Sector Breakdown:")
        for sector, data in metrics['breakdown_by_sector'].items():
            print(f"    {sector}: ${data['value']:,.2f} ({data['percentage']:.1f}%) - {data['count']} investments")
        print()
    
    # Top Performers
    if metrics['top_performers']:
        print("  Top Performers:")
        for perf in metrics['top_performers']:
            print(f"    {perf['symbol']} ({perf['name']}): {perf['gain_loss_percent']:.2f}%")
        print()
    
    # Worst Performers
    if metrics['worst_performers']:
        print("  Worst Performers:")
        for perf in metrics['worst_performers']:
            print(f"    {perf['symbol']} ({perf['name']}): {perf['gain_loss_percent']:.2f}%")
        print()


def main():
    """Main demo script."""
    
    print_section("Investment Portfolio Agent - Demo")
    
    
    # Get database session
    db = SessionLocal()
    
    try:
        # Initialize repositories
        portfolio_calculator = PortfolioCalculator(db)
        
        
        # Calculate portfolio metrics
        print_section("Calculating Portfolio Metrics")
        
        metrics = portfolio_calculator.calculate_portfolio_metrics("14f76fb0-96d2-49d5-84e7-e0f5a7f05cd4")
        print_metrics(metrics)
        
    except Exception as e:
        print(f"\n[ERROR] Error during demo: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        db.close()


if __name__ == "__main__":
    main()

