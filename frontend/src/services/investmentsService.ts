import { api } from './api';
import type {
  Investment,
  InvestmentCreate,
  InvestmentUpdate,
  PriceHistoryResponse,
} from '@types/index';

export const investmentsService = {
  async createInvestment(data: InvestmentCreate): Promise<Investment> {
    const response = await api.post<Investment>('/investment/investments', data);
    return response.data;
  },

  async updateInvestment(investmentId: string, data: InvestmentUpdate): Promise<Investment> {
    const response = await api.patch<Investment>(`/investment/investments/${investmentId}`, data);
    return response.data;
  },

  async getUserInvestments(params?: {
    skip?: number;
    limit?: number;
    active_only?: boolean;
  }): Promise<Investment[]> {
    const response = await api.get<Investment[]>('/investment/investments', { params });
    return response.data;
  },

  async getPriceHistory(
    investmentId: string,
    params?: {
      start_date?: string;
      end_date?: string;
    }
  ): Promise<PriceHistoryResponse> {
    const response = await api.get<PriceHistoryResponse>(
      `/investment/investments/${investmentId}/price-history`,
      { params }
    );
    return response.data;
  },
};
