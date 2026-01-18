import { api } from './api';
import type {
  Investment,
  InvestmentCreate,
  InvestmentUpdate,
  PriceHistoryResponse,
} from '@types/index';

/**
 * Investments service for managing user investments
 */
export const investmentsService = {
  /**
   * Create a new investment
   */
  async createInvestment(data: InvestmentCreate): Promise<Investment> {
    const response = await api.post<Investment>('/investments', data);
    return response.data;
  },

  /**
   * Update an investment
   */
  async updateInvestment(investmentId: string, data: InvestmentUpdate): Promise<Investment> {
    const response = await api.patch<Investment>(`/investments/${investmentId}`, data);
    return response.data;
  },

  /**
   * Get user's investments
   */
  async getUserInvestments(params?: {
    skip?: number;
    limit?: number;
    active_only?: boolean;
  }): Promise<Investment[]> {
    const response = await api.get<Investment[]>('/users/me/investments', { params });
    return response.data;
  },

  /**
   * Get price history for an investment
   */
  async getPriceHistory(
    investmentId: string,
    params?: {
      start_date?: string;
      end_date?: string;
    }
  ): Promise<PriceHistoryResponse> {
    const response = await api.get<PriceHistoryResponse>(
      `/investments/${investmentId}/price-history`,
      { params }
    );
    return response.data;
  },
};
