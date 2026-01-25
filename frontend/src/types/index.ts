// User types
export interface User {
  id: string;
  email: string;
  full_name: string;
  currency_preference: string;
  risk_tolerance: 'conservative' | 'moderate' | 'aggressive';
  is_active: boolean;
  email_verified: boolean;
  last_login: string | null;
  created_at: string;
  updated_at: string;
}

export interface UserUpdate {
  email?: string;
  full_name?: string;
  currency_preference?: string;
  risk_tolerance?: 'conservative' | 'moderate' | 'aggressive';
}

// Auth types
export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
  full_name: string;
  currency_preference?: string;
  risk_tolerance?: 'conservative' | 'moderate' | 'aggressive';
}

export interface TokenResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
  expires_in: number;
}

// Investment types
export type AssetType = 'stock' | 'etf' | 'bond' | 'crypto' | 'commodity' | 'other';
export type MarketCapCategory = 'large' | 'mid' | 'small' | 'mega';

export interface Investment {
  id: string;
  user_id: string;
  symbol: string;
  name: string;
  asset_type: AssetType;
  country: string;
  sector: string | null;
  industry: string | null;
  market_cap_category: MarketCapCategory | null;
  purchase_date: string;
  purchase_price: number;
  quantity: number;
  currency: string;
  current_price: number | null;
  current_value: number | null;
  gain_loss: number | null;
  gain_loss_percent: number | null;
  dividend_yield: number | null;
  expense_ratio: number | null;
  notes: string | null;
  is_active: boolean;
  performance_status: 'profitable' | 'losing' | 'neutral';
  created_at: string;
  updated_at: string;
}

export interface InvestmentCreate {
  account_type: 'CTO' | 'PEA';
  ticker_symbol?: string;
  isin?: string;
  purchase_date: string;
  quantity: number;
}

export interface InvestmentUpdate {
  ticker_symbol: string;
}

// Price History types
export interface PriceHistoryPoint {
  timestamp: string;
  price: number;
  open_price: number | null;
  high_price: number | null;
  low_price: number | null;
  close_price: number | null;
  adjusted_close: number | null;
  volume: number | null;
  market_cap: number | null;
  dividend_amount: number | null;
  split_ratio: number | null;
  source: string;
  data_quality: 'good' | 'estimated' | 'interpolated' | 'stale' | 'missing';
}

export interface PriceHistoryResponse {
  investment_id: string;
  symbol: string;
  data_points: PriceHistoryPoint[];
  total_points: number;
  start_date: string | null;
  end_date: string | null;
}

// Portfolio types
export interface PortfolioBreakdown {
  category: string;
  value: number;
  percentage: number;
  count: number;
}

export interface TopPerformer {
  investment_id: string;
  symbol: string;
  name: string;
  gain_loss_percent: number;
}

export interface PortfolioMetrics {
  user_id: string;
  total_value: number;
  total_cost: number;
  total_gain_loss: number;
  total_gain_loss_percent: number;
  diversification_score: number;
  investment_count: number;
  breakdown_by_country: Record<string, PortfolioBreakdown>;
  breakdown_by_sector: Record<string, PortfolioBreakdown>;
  breakdown_by_asset_type: Record<string, PortfolioBreakdown>;
  top_performers: TopPerformer[];
  worst_performers: TopPerformer[];
  currency: string;
}

export interface PortfolioHistoryPoint {
  timestamp: string;
  total_value: number;
  total_cost: number;
  total_gain_loss: number;
}

export interface PortfolioHistoryResponse {
  user_id: string;
  data_points: PortfolioHistoryPoint[];
  total_points: number;
  start_date: string | null;
  end_date: string | null;
}

// API Error types
export interface APIError {
  detail: string;
  status?: number;
}

// AI Agent Streaming Event types
export type AgentEventType = 'agent_change' | 'tool_call' | 'tool_output' | 'message' | 'final_output' | 'error';

export interface AgentChangeEvent {
  type: 'agent_change';
  agent_name: string;
}

export interface ToolCallEvent {
  type: 'tool_call';
  tool_name: string;
  arguments: string;
}

export interface ToolOutputEvent {
  type: 'tool_output';
  output: string;
}

export interface MessageEvent {
  type: 'message';
  content: string;
}

export interface FinalOutputEvent {
  type: 'final_output';
  recommendation: string;
}

export interface ErrorEvent {
  type: 'error';
  message: string;
}

export type AgentStreamEvent =
  | AgentChangeEvent
  | ToolCallEvent
  | ToolOutputEvent
  | MessageEvent
  | FinalOutputEvent
  | ErrorEvent;
