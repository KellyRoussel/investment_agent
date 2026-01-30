"""Remove portfolio_snapshots table

Revision ID: 003_remove_portfolio_snapshots
Revises: 002_remove_price_history
Create Date: 2026-01-30

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = '003_remove_portfolio_snapshots'
down_revision: Union[str, None] = '002_remove_price_history'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Drop the portfolio_snapshots table
    op.drop_table('portfolio_snapshots')


def downgrade() -> None:
    # Re-create the portfolio_snapshots table
    op.create_table(
        'portfolio_snapshots',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('snapshot_date', sa.Date(), nullable=False),
        sa.Column('total_value', sa.Numeric(15, 2), nullable=False),
        sa.Column('total_cost', sa.Numeric(15, 2), nullable=False),
        sa.Column('total_gain_loss', sa.Numeric(15, 2), nullable=False),
        sa.Column('total_gain_loss_percent', sa.Numeric(8, 4), nullable=False),
        sa.Column('diversification_score', sa.Numeric(3, 2), nullable=True),
        sa.Column('risk_score', sa.Numeric(3, 2), nullable=True),
        sa.Column('currency', sa.String(3), nullable=False, server_default='USD'),
        sa.Column('investment_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('breakdown_by_country', postgresql.JSONB(), nullable=True),
        sa.Column('breakdown_by_sector', postgresql.JSONB(), nullable=True),
        sa.Column('breakdown_by_asset_type', postgresql.JSONB(), nullable=True),
        sa.Column('top_performers', postgresql.JSONB(), nullable=True),
        sa.Column('worst_performers', postgresql.JSONB(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    )

    # Create indexes
    op.create_index('ix_portfolio_snapshots_user_id', 'portfolio_snapshots', ['user_id'])
    op.create_index('ix_portfolio_snapshots_snapshot_date', 'portfolio_snapshots', ['snapshot_date'])
