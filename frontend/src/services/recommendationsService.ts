import { api } from './api';

export interface RecommendationResponse {
  recommendation: string;
}

/**
 * Recommendations service for AI-powered investment recommendations
 */
export const recommendationsService = {
  /**
   * Generate AI-powered investment recommendations
   */
  async generateRecommendation(): Promise<RecommendationResponse> {
    const response = await api.post<RecommendationResponse>('/recommendations/generate');
    return response.data;
  },
};
