"""Remove price_history table

Revision ID: 002_remove_price_history
Revises: 001_remove_current_price
Create Date: 2026-01-30

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = '002_remove_price_history'
down_revision: Union[str, None] = '001_remove_current_price'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Drop all check constraints first
    op.drop_constraint('chk_positive_price', 'price_history', type_='check')
    op.drop_constraint('chk_positive_open_price', 'price_history', type_='check')
    op.drop_constraint('chk_positive_high_price', 'price_history', type_='check')
    op.drop_constraint('chk_positive_low_price', 'price_history', type_='check')
    op.drop_constraint('chk_positive_close_price', 'price_history', type_='check')
    op.drop_constraint('chk_positive_adjusted_close', 'price_history', type_='check')
    op.drop_constraint('chk_non_negative_market_cap', 'price_history', type_='check')
    op.drop_constraint('chk_non_negative_volume', 'price_history', type_='check')
    op.drop_constraint('chk_non_negative_dividend', 'price_history', type_='check')
    op.drop_constraint('chk_positive_split_ratio', 'price_history', type_='check')

    # Drop the price_history table
    op.drop_table('price_history')


def downgrade() -> None:
    # Re-create the price_history table
    op.create_table(
        'price_history',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('investment_id', sa.UUID(), nullable=False),
        sa.Column('price', sa.Numeric(15, 4), nullable=False),
        sa.Column('open_price', sa.Numeric(15, 4), nullable=True),
        sa.Column('high_price', sa.Numeric(15, 4), nullable=True),
        sa.Column('low_price', sa.Numeric(15, 4), nullable=True),
        sa.Column('close_price', sa.Numeric(15, 4), nullable=True),
        sa.Column('adjusted_close', sa.Numeric(15, 4), nullable=True),
        sa.Column('market_cap', sa.BigInteger(), nullable=True),
        sa.Column('volume', sa.BigInteger(), nullable=True),
        sa.Column('dividend_amount', sa.Numeric(10, 4), nullable=True),
        sa.Column('split_ratio', sa.Numeric(8, 4), nullable=True),
        sa.Column('timestamp', sa.DateTime(timezone=True), nullable=False),
        sa.Column('source', sa.String(50), nullable=False, server_default='yahoo_finance'),
        sa.Column('data_quality', sa.Enum('GOOD', 'DELAYED', 'ESTIMATED', 'MISSING', name='dataquality'), nullable=False, server_default='GOOD'),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['investment_id'], ['investments.id'], ondelete='CASCADE'),
    )

    # Create indexes
    op.create_index('ix_price_history_investment_id', 'price_history', ['investment_id'])
    op.create_index('ix_price_history_timestamp', 'price_history', ['timestamp'])

    # Re-create check constraints
    op.create_check_constraint('chk_positive_price', 'price_history', 'price > 0')
    op.create_check_constraint('chk_positive_open_price', 'price_history', 'open_price IS NULL OR open_price > 0')
    op.create_check_constraint('chk_positive_high_price', 'price_history', 'high_price IS NULL OR high_price > 0')
    op.create_check_constraint('chk_positive_low_price', 'price_history', 'low_price IS NULL OR low_price > 0')
    op.create_check_constraint('chk_positive_close_price', 'price_history', 'close_price IS NULL OR close_price > 0')
    op.create_check_constraint('chk_positive_adjusted_close', 'price_history', 'adjusted_close IS NULL OR adjusted_close > 0')
    op.create_check_constraint('chk_non_negative_market_cap', 'price_history', 'market_cap IS NULL OR market_cap >= 0')
    op.create_check_constraint('chk_non_negative_volume', 'price_history', 'volume IS NULL OR volume >= 0')
    op.create_check_constraint('chk_non_negative_dividend', 'price_history', 'dividend_amount IS NULL OR dividend_amount >= 0')
    op.create_check_constraint('chk_positive_split_ratio', 'price_history', 'split_ratio IS NULL OR split_ratio > 0')
