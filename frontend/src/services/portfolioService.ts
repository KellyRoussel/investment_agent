import { api } from './api';
import type { PortfolioMetrics, PortfolioHistoryResponse } from '@types/index';

export const portfolioService = {
  async getPortfolioMetrics(): Promise<PortfolioMetrics> {
    const response = await api.get<PortfolioMetrics>('/investment/portfolio/metrics');
    return response.data;
  },

  async getPortfolioHistory(params?: {
    start_date?: string;
    end_date?: string;
  }): Promise<PortfolioHistoryResponse> {
    const response = await api.get<PortfolioHistoryResponse>('/investment/portfolio/price-history', {
      params,
    });
    return response.data;
  },
};
