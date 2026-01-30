"""Remove current_price column from investments table

Revision ID: 001_remove_current_price
Revises:
Create Date: 2026-01-30

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '001_remove_current_price'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Drop the check constraint first
    op.drop_constraint('chk_positive_current_price', 'investments', type_='check')

    # Drop the current_price column
    op.drop_column('investments', 'current_price')


def downgrade() -> None:
    # Re-add the current_price column
    op.add_column('investments', sa.Column('current_price', sa.Numeric(15, 4), nullable=True))

    # Re-add the check constraint
    op.create_check_constraint(
        'chk_positive_current_price',
        'investments',
        'current_price IS NULL OR current_price > 0'
    )
