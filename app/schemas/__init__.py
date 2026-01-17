"""
Schémas Pydantic pour les API.
"""
from .base import (
    BaseSchema,
    TimestampSchema,
    IDSchema,
    BaseResponseSchema,
    PaginationSchema,
    PaginatedResponseSchema,
    ErrorDetailSchema,
    ErrorResponseSchema
)
from .investment import (
    InvestmentSearchResult,
    InvestmentSearchResponse,
    InvestmentCreate,
    InvestmentUpdate,
    InvestmentQuantityUpdate,
    InvestmentResponse,
    InvestmentSummary,
    InvestmentListResponse,
    InvestmentDeleteResponse
)
from .portfolio import (
    PortfolioBreakdown,
    TopPerformer,
    PortfolioSummary,
    DiversificationAnalysis,
    PerformanceAnalysis,
    PortfolioSnapshot,
    PortfolioSnapshotList,
    PortfolioComparison
)
from .price import (
    PriceHistoryItem,
    PriceHistoryResponse,
    PriceUpdateRequest,
    PriceUpdateResponse,
    PriceUpdateItem,
    PriceUpdateDetailResponse,
    MarketData,
    MarketDataResponse,
    PriceAlert,
    PriceAlertCreate
)
from .user import (
    UserCreate,
    UserUpdate,
    UserResponse,
    UserListResponse
)
from .recommendation import (
    InvestmentPreferences,
    RecommendationRequest,
    RecommendationItem,
    MarketAnalysis,
    PortfolioImpact,
    RecommendationResponse,
    RecommendationSummary,
    RecommendationListResponse,
    RecommendationApplyRequest,
    RecommendationDismissRequest,
    RecommendationFeedback
)

__all__ = [
    # Base schemas
    'BaseSchema',
    'TimestampSchema',
    'IDSchema',
    'BaseResponseSchema',
    'PaginationSchema',
    'PaginatedResponseSchema',
    'ErrorDetailSchema',
    'ErrorResponseSchema',
    
    # Investment schemas
    'InvestmentSearchResult',
    'InvestmentSearchResponse',
    'InvestmentCreate',
    'InvestmentUpdate',
    'InvestmentQuantityUpdate',
    'InvestmentResponse',
    'InvestmentSummary',
    'InvestmentListResponse',
    'InvestmentDeleteResponse',
    
    # Portfolio schemas
    'PortfolioBreakdown',
    'TopPerformer',
    'PortfolioSummary',
    'DiversificationAnalysis',
    'PerformanceAnalysis',
    'PortfolioSnapshot',
    'PortfolioSnapshotList',
    'PortfolioComparison',
    
    # Price schemas
    'PriceHistoryItem',
    'PriceHistoryResponse',
    'PriceUpdateRequest',
    'PriceUpdateResponse',
    'PriceUpdateItem',
    'PriceUpdateDetailResponse',
    'MarketData',
    'MarketDataResponse',
    'PriceAlert',
    'PriceAlertCreate',

    # User schemas
    'UserCreate',
    'UserUpdate',
    'UserResponse',
    'UserListResponse',
    
    # Recommendation schemas
    'InvestmentPreferences',
    'RecommendationRequest',
    'RecommendationItem',
    'MarketAnalysis',
    'PortfolioImpact',
    'RecommendationResponse',
    'RecommendationSummary',
    'RecommendationListResponse',
    'RecommendationApplyRequest',
    'RecommendationDismissRequest',
    'RecommendationFeedback',
]
