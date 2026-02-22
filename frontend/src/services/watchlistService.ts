import { api } from './api';
import type { WatchlistItem, WatchlistItemCreate } from '@types/index';

export const watchlistService = {
  async getWatchlist(): Promise<WatchlistItem[]> {
    const response = await api.get<WatchlistItem[]>('/investment/watchlist');
    return response.data;
  },

  async addItem(data: WatchlistItemCreate): Promise<WatchlistItem> {
    const response = await api.post<WatchlistItem>('/investment/watchlist', data);
    return response.data;
  },

  async removeItem(itemId: string): Promise<void> {
    await api.delete(`/investment/watchlist/${itemId}`);
  },
};
