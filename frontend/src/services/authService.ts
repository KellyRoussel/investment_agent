import { storage } from '@utils/storage';
import type { OAuthExchangeResponse, User } from '@types/index';

const APP_NAME = 'investment_agent';
const API_URL = import.meta.env.VITE_API_URL || '';
const WEB_CALLBACK_REDIRECT_URI = `${API_URL}/auth/web-callback/${APP_NAME}`;

export const authService = {
  /**
   * Get Google OAuth authorization URL and redirect the browser to Google login.
   * The redirect_uri_override tells myBackend to use the web callback endpoint
   * instead of the mobile deep link callback.
   */
  async loginWithGoogle(): Promise<void> {
    const params = new URLSearchParams({
      redirect_uri_override: WEB_CALLBACK_REDIRECT_URI,
    });
    const response = await fetch(`${API_URL}/login/google/${APP_NAME}?${params}`);
    if (!response.ok) {
      throw new Error('Failed to get Google auth URL');
    }
    const data = await response.json();
    window.location.href = data.authorization_url;
  },

  /**
   * Exchange OAuth code + state for JWT tokens.
   * Called from the AuthCallback page after Google redirects back.
   */
  async handleOAuthCallback(code: string, state: string): Promise<User> {
    const params = new URLSearchParams({
      code,
      service: 'GOOGLE',
      state,
      redirect_uri_override: WEB_CALLBACK_REDIRECT_URI,
    });
    const response = await fetch(`${API_URL}/auth/exchange/${APP_NAME}?${params}`);
    if (!response.ok) {
      const error = await response.json().catch(() => ({ detail: 'Authentication failed' }));
      throw new Error(error.detail || 'Authentication failed');
    }
    const data: OAuthExchangeResponse = await response.json();

    storage.setTokens(data.access_token, data.refresh_token);
    storage.setUser(data.user);

    return data.user;
  },

  /**
   * Logout user and clear stored data
   */
  logout(): void {
    storage.clearAll();
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
