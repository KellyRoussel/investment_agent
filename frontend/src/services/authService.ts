import { api } from './api';
import { storage } from '@utils/storage';
import type { LoginRequest, RegisterRequest, TokenResponse, User } from '@types/index';

/**
 * Authentication service for user registration, login, and token management
 */
export const authService = {
  /**
   * Register a new user
   */
  async register(data: RegisterRequest): Promise<TokenResponse> {
    const response = await api.post<TokenResponse>('/auth/register', data);
    const tokens = response.data;

    // Store tokens
    storage.setTokens(tokens.access_token, tokens.refresh_token);

    // Fetch and store user data
    await this.getCurrentUser();

    return tokens;
  },

  /**
   * Login with email and password
   */
  async login(data: LoginRequest): Promise<TokenResponse> {
    const response = await api.post<TokenResponse>('/auth/login', data);
    const tokens = response.data;

    // Store tokens
    storage.setTokens(tokens.access_token, tokens.refresh_token);

    // Fetch and store user data
    await this.getCurrentUser();

    return tokens;
  },

  /**
   * Logout user and clear stored data
   */
  logout(): void {
    storage.clearAll();
  },

  /**
   * Get current authenticated user
   */
  async getCurrentUser(): Promise<User> {
    const response = await api.get<User>('/auth/me');
    const user = response.data;

    // Store user data
    storage.setUser(user);

    return user;
  },

  /**
   * Refresh access token
   */
  async refreshToken(): Promise<TokenResponse> {
    const refreshToken = storage.getRefreshToken();
    if (!refreshToken) {
      throw new Error('No refresh token available');
    }

    const response = await api.post<TokenResponse>('/auth/refresh', {
      refresh_token: refreshToken,
    });

    const tokens = response.data;
    storage.setTokens(tokens.access_token, tokens.refresh_token);

    return tokens;
  },

  /**
   * Check if user is authenticated
   */
  isAuthenticated(): boolean {
    return !!storage.getAccessToken();
  },

  /**
   * Get stored user data
   */
  getStoredUser(): User | null {
    const userData = storage.getUser();
    if (!userData) return null;

    try {
      return JSON.parse(userData) as User;
    } catch {
      return null;
    }
  },
};
