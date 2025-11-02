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

# Ensure repo root and app package are on sys.path so both
# `app.*` absolute imports and plain `repositories` style imports
# (when executed as a script) resolve.
repo_root = Path(__file__).resolve().parents[1]
if str(repo_root) not in sys.path:
    sys.path.insert(0, str(repo_root))
app_package_dir = repo_root / "app"
if str(app_package_dir) not in sys.path:
    sys.path.insert(0, str(app_package_dir))

from app.database import create_tables, SessionLocal
from app.models.user import RiskTolerance
from app.models.investment import AssetType, MarketCapCategory
from app.repositories import UserRepository, InvestmentRepository
from app.services.portfolio_calculator import PortfolioCalculator




def main():
    """Main demo script."""
    
    
    # Get database session
    db = SessionLocal()
    
    try:
        # Initialize repositories
        investment_repo = InvestmentRepository(db)
        portfolio_calculator = PortfolioCalculator(db)
        
        investments_list = investment_repo.get_by_user("14f76fb0-96d2-49d5-84e7-e0f5a7f05cd4")
        print([i.model_dump() for i in investments_list])
        exit()
        
        # Calculate portfolio metrics
        metrics = portfolio_calculator.calculate_portfolio_metrics("14f76fb0-96d2-49d5-84e7-e0f5a7f05cd4")
        
        
    except Exception as e:
        print(f"\n[ERROR] Error during demo: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        db.close()


if __name__ == "__main__":
    main()

