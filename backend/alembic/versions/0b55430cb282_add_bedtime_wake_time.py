"""add_bedtime_wake_time

Revision ID: 0b55430cb282
Revises: 0001_initial
Create Date: 2026-07-01 11:12:49.091871

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = '0b55430cb282'
down_revision: Union[str, Sequence[str], None] = '0001_initial'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('user_profiles', sa.Column('bedtime', sa.Time(), nullable=True))
    op.add_column('user_profiles', sa.Column('wake_time', sa.Time(), nullable=True))


def downgrade() -> None:
    op.drop_column('user_profiles', 'wake_time')
    op.drop_column('user_profiles', 'bedtime')