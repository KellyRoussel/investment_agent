// User types
export interface User {
  id: string;
  email: string;
  name: string;
  username: string;
  picture: string;
  provider: string;
}

export interface InvestmentProfile {
  currency_preference: string;
  risk_tolerance: 'conservative' | 'moderate' | 'aggressive';
  investment_horizon: string | null;
  ethical_exclusions: string | null;
  country: string | null;
  interests: string | null;
  last_macro_context: string | null;
}

export interface InvestmentProfileUpdate {
  currency_preference?: string;
  risk_tolerance?: 'conservative' | 'moderate' | 'aggressive';
  investment_horizon?: string;
  ethical_exclusions?: string;
  country?: string;
  interests?: string;
}

// Auth types
export interface TokenResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
}

export interface OAuthExchangeResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
  user: User;
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
  dividend_yield: number | null;
  expense_ratio: number | null;
  notes: string | null;
  investment_thesis: string | null;
  thesis_status: 'valid' | 'watch' | 'reconsider' | null;
  alert_threshold_pct: number | null;
  account_type: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface InvestmentCreate {
  account_type: 'CTO' | 'PEA';
  ticker_symbol?: string;
  isin?: string;
  purchase_date: string;
  quantity: number;
  notes?: string;
  investment_thesis?: string;
  thesis_status?: 'valid' | 'watch' | 'reconsider';
  alert_threshold_pct?: number;
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

// Investment suggestion (emitted by the agent at end of workflow)
export interface InvestmentSuggestion {
  symbol: string;
  name: string;
  account_type: 'CTO' | 'PEA';
  allocation_eur: number | null;
  current_price: number | null;
  currency: string;
  suggested_quantity: number | null;
  investment_thesis: string | null;
  notes: string | null;
  alert_threshold_pct: number | null;
}

// Pre-fill values passed to AddInvestmentModal when opening from a suggestion
export interface InvestmentInitialValues {
  account_type?: 'CTO' | 'PEA';
  ticker_symbol?: string;
  suggested_quantity?: number | null;
  investment_thesis?: string | null;
  notes?: string | null;
  alert_threshold_pct?: number | null;
}

// AI Agent Streaming Event types (v2 — DeepAgents workflow)
export type AgentEventType = 'workflow_start' | 'step_start' | 'step_complete' | 'tool_call' | 'token' | 'final_report' | 'workflow_complete' | 'investment_suggestions' | 'error';

export interface WorkflowStartEvent {
  type: 'workflow_start';
  report_id: string;
  message: string;
}

export interface StepStartEvent {
  type: 'step_start';
  step: number;
  step_name: string;
}

export interface StepCompleteEvent {
  type: 'step_complete';
  step: number;
  step_name: string;
  result?: string;
}

export interface ToolCallEvent {
  type: 'tool_call';
  tool: string;
  inputs: Record<string, string>;
}

export interface TokenEvent {
  type: 'token';
  content: string;
  agent: string;
}

export interface WorkflowCompleteEvent {
  type: 'workflow_complete';
  report_id: string;
  message: string;
}

export interface FinalReportEvent {
  type: 'final_report';
  content: string;
}

export interface InvestmentSuggestionsEvent {
  type: 'investment_suggestions';
  suggestions: InvestmentSuggestion[];
}

export interface ErrorEvent {
  type: 'error';
  message: string;
}

export type AgentStreamEvent =
  | WorkflowStartEvent
  | StepStartEvent
  | StepCompleteEvent
  | ToolCallEvent
  | TokenEvent
  | FinalReportEvent
  | WorkflowCompleteEvent
  | InvestmentSuggestionsEvent
  | ErrorEvent;
