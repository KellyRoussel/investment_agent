import { api } from './api';
import type { User, UserUpdate } from '@types/index';

/**
 * User management service
 */
export const usersService = {
  /**
   * Update user profile
   */
  async updateUser(userId: string, data: UserUpdate): Promise<User> {
    const response = await api.patch<User>(`/users/${userId}`, data);
    return response.data;
  },
};
