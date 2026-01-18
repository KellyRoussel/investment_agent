import { api } from './api';
import type { PortfolioMetrics, PortfolioHistoryResponse } from '@types/index';

/**
 * Portfolio service for managing portfolio metrics and history
 */
export const portfolioService = {
  /**
   * Get portfolio metrics for the current user
   */
  async getPortfolioMetrics(): Promise<PortfolioMetrics> {
    const response = await api.get<PortfolioMetrics>('/portfolio/me/metrics');
    return response.data;
  },

  /**
   * Get portfolio value history
   */
  async getPortfolioHistory(params?: {
    start_date?: string;
    end_date?: string;
  }): Promise<PortfolioHistoryResponse> {
    const response = await api.get<PortfolioHistoryResponse>('/portfolio/me/price-history', {
      params,
    });
    return response.data;
  },
};
