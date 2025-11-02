
import asyncio

from services.ai_agents import launch_agents
from database import SessionLocal
from repositories import InvestmentRepository
from services.portfolio_calculator import PortfolioCalculator




async def main():
    """Main demo script."""
    
    
    # Get database session
    db = SessionLocal()
    
    try:
        # Initialize repositories
        investment_repo = InvestmentRepository(db)
        portfolio_calculator = PortfolioCalculator(db)
        
        investments_list = investment_repo.get_by_user("14f76fb0-96d2-49d5-84e7-e0f5a7f05cd4")
        domain_list =[i.to_domain() for i in investments_list]
        
        
        # Calculate portfolio metrics
        metrics = portfolio_calculator.calculate_portfolio_metrics("14f76fb0-96d2-49d5-84e7-e0f5a7f05cd4")
        
        result = await launch_agents(domain_list, metrics)
        print("\n[AGENT OUTPUT]")
        print(result)
    except Exception as e:
        print(f"\n[ERROR] Error during demo: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        db.close()


if __name__ == "__main__":

    asyncio.run(main())

