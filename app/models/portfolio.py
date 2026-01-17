"""
Modèle de base de données pour les snapshots de portfolio.
"""
from sqlalchemy import Column, Integer, Date, String, ForeignKey, Numeric
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship

from .base import BaseModel, GUID


class PortfolioSnapshot(BaseModel):
    """
    Modèle snapshot de portfolio.
    
    NOTE: Les métriques sont stockées uniquement dans les snapshots
    pour l'historique. Les métriques actuelles sont calculées à la volée.
    """
    
    __tablename__ = "portfolio_snapshots"
    
    # Relations
    user_id = Column(
        GUID,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        comment="ID de l'utilisateur"
    )
    
    # Métadonnées du snapshot
    snapshot_date = Column(
        Date,
        nullable=False,
        index=True,
        comment="Date du snapshot"
    )
    
    # Métriques globales (stockées pour l'historique)
    total_value = Column(
        Numeric(15, 2),
        nullable=False,
        comment="Valeur totale du portfolio à cette date"
    )
    
    total_cost = Column(
        Numeric(15, 2),
        nullable=False,
        comment="Coût total du portfolio à cette date"
    )
    
    total_gain_loss = Column(
        Numeric(15, 2),
        nullable=False,
        comment="Gain/perte total à cette date"
    )
    
    total_gain_loss_percent = Column(
        Numeric(8, 4),
        nullable=False,
        comment="Gain/perte total en pourcentage à cette date"
    )
    
    # Scores d'analyse (stockés pour l'historique)
    diversification_score = Column(
        Numeric(3, 2),
        nullable=True,
        comment="Score de diversification à cette date"
    )
    
    risk_score = Column(
        Numeric(3, 2),
        nullable=True,
        comment="Score de risque à cette date"
    )
    
    # Devise et comptage
    currency = Column(
        String(3),
        nullable=False,
        default="USD",
        comment="Devise principale du portfolio"
    )
    
    investment_count = Column(
        Integer,
        nullable=False,
        default=0,
        comment="Nombre total d'investissements à cette date"
    )
    
    # Répartitions (stockées en JSON pour l'historique)
    breakdown_by_country = Column(
        JSONB,
        nullable=True,
        comment="Répartition par pays à cette date"
    )
    
    breakdown_by_sector = Column(
        JSONB,
        nullable=True,
        comment="Répartition par secteur à cette date"
    )
    
    breakdown_by_asset_type = Column(
        JSONB,
        nullable=True,
        comment="Répartition par type d'actif à cette date"
    )
    
    # Performeurs (stockés en JSON pour l'historique)
    top_performers = Column(
        JSONB,
        nullable=True,
        comment="Meilleurs performeurs à cette date"
    )
    
    worst_performers = Column(
        JSONB,
        nullable=True,
        comment="Pires performeurs à cette date"
    )
    
    # Relations
    user = relationship(
        "User",
        back_populates="portfolio_snapshots",
        lazy="select"
    )
    
    def __repr__(self) -> str:
        return f"<PortfolioSnapshot(id={self.id}, user_id={self.user_id}, date='{self.snapshot_date}', total_value={self.total_value})>"