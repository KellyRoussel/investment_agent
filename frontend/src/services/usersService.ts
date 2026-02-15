import { api } from './api';
import type { InvestmentProfile, InvestmentProfileUpdate } from '@types/index';

const INVESTMENT_PROFILE_KEY = 'investment_profile';

export const usersService = {
  async updateInvestmentProfile(data: InvestmentProfileUpdate): Promise<InvestmentProfile> {
    const response = await api.patch<InvestmentProfile>('/investment/profile', data);
    localStorage.setItem(INVESTMENT_PROFILE_KEY, JSON.stringify(response.data));
    return response.data;
  },

  getStoredInvestmentProfile(): InvestmentProfile | null {
    const raw = localStorage.getItem(INVESTMENT_PROFILE_KEY);
    if (!raw) return null;
    try {
      return JSON.parse(raw) as InvestmentProfile;
    } catch {
      return null;
    }
  },
};
