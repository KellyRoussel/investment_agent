import uuid
from typing import Optional

import streamlit as st
import sys
from pathlib import Path

# Ensure the repository root is on sys.path so `from app...` imports work
# when Streamlit executes this file as a script. The app package lives two
# levels above this file (repo_root/app/ui -> parents[2] == repo root).
repo_root = Path(__file__).resolve().parents[2]
if str(repo_root) not in sys.path:
    sys.path.insert(0, str(repo_root))
    # Also insert the `app` package dir so imports like `domain.*` (which
    # live under app/domain) resolve when modules import them as top-level
    # `domain` packages.
    app_package_dir = repo_root / "app"
    if str(app_package_dir) not in sys.path:
        sys.path.insert(0, str(app_package_dir))

from app.database import SessionLocal
from app.services.portfolio_calculator import PortfolioCalculator
from app.repositories.investment_repository import InvestmentRepository


def get_db_session():
    return SessionLocal()


def parse_user_id(user_id_str: str) -> Optional[uuid.UUID]:
    try:
        return uuid.UUID(user_id_str)
    except Exception:
        return None


def display_metrics(metrics: dict):
    currency = metrics.get("currency", "USD")
    st.subheader("Portfolio summary")
    cols = st.columns(4)
    cols[0].metric("Total value", f"{metrics['total_value']:.2f} {currency}")
    cols[1].metric("Total cost", f"{metrics['total_cost']:.2f} {currency}")
    cols[2].metric("Gain / Loss", f"{metrics['total_gain_loss']:.2f} {currency}")
    cols[3].metric("Gain %", f"{metrics['total_gain_loss_percent']:.2f}%")

    st.write(f"**Investments:** {metrics.get('investment_count', 0)}")
    st.write(f"**Diversification score:** {metrics.get('diversification_score', 0):.2f}")

    st.markdown("---")

    st.subheader("Breakdown by country")
    st.table(metrics.get("breakdown_by_country", {}))

    st.subheader("Breakdown by sector")
    st.table(metrics.get("breakdown_by_sector", {}))

    st.subheader("Breakdown by asset type")
    st.table(metrics.get("breakdown_by_asset_type", {}))


def display_investments(investments, calculator: PortfolioCalculator):
    st.subheader("Investments")
    if not investments:
        st.info("No investments found for this user.")
        return

    rows = []
    for inv in investments:
        inv_metrics = calculator.calculate_investment_metrics(inv)
        rows.append({
            "symbol": inv.symbol,
            "name": inv.name,
            "quantity": float(inv.quantity),
            "purchase_price": float(inv.purchase_price),
            "current_price": float(inv.current_price) if inv.current_price is not None else None,
            "current_value": inv_metrics.get("current_value"),
            "gain_loss": inv_metrics.get("gain_loss"),
            "gain_loss_percent": inv_metrics.get("gain_loss_percent"),
            "performance_status": inv_metrics.get("performance_status"),
        })

    st.table(rows)


def main():
    st.title("Investment Portfolio Explorer")
    st.markdown("Enter a user ID to load investments and portfolio metrics.")

    user_id_input = st.text_input("User ID (UUID)")
    load_button = st.button("Load portfolio")

    if load_button:
        user_uuid = parse_user_id(user_id_input)
        if user_uuid is None:
            st.error("Invalid UUID provided. Please enter a valid user UUID.")
            return

        session = get_db_session()
        try:
            calculator = PortfolioCalculator(session)
            repo = InvestmentRepository(session)

            with st.spinner("Calculating portfolio metrics..."):
                metrics = calculator.calculate_portfolio_metrics(user_uuid)
                investments = repo.get_by_user(user_uuid, active_only=True, limit=1000)

            display_metrics(metrics)
            display_investments(investments, calculator)

        except Exception as exc:
            st.exception(exc)
        finally:
            session.close()


if __name__ == "__main__":
    main()
