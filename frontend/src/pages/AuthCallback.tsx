import { useEffect, useRef, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { authService } from '@services/authService';
import { LoadingSpinner } from '@components/common/LoadingSpinner';
import { useAuth } from '@hooks/useAuth';

export function AuthCallback() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { login } = useAuth();
  const [error, setError] = useState<string | null>(null);
  const hasProcessed = useRef(false);

  useEffect(() => {
    // Prevent double-execution in React StrictMode
    if (hasProcessed.current) return;
    hasProcessed.current = true;

    const code = searchParams.get('code');
    const state = searchParams.get('state');
    const errorParam = searchParams.get('error');

    if (errorParam) {
      setError(`Google authentication error: ${errorParam}`);
      return;
    }

    if (!code || !state) {
      setError('Missing authentication parameters. Please try again.');
      return;
    }

    authService
      .handleOAuthCallback(code, state)
      .then((user) => {
        login(user);
        navigate('/portfolio', { replace: true });
      })
      .catch((err: any) => {
        console.error('OAuth callback error:', err);
        setError(err.message || 'Authentication failed. Please try again.');
      });
  }, []);

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#0a0e27] px-4">
        <div className="w-full max-w-md text-center">
          <div className="bg-[#ef4444]/10 border border-[#ef4444]/50 rounded-lg p-6 mb-6">
            <p className="text-[#ef4444] font-medium mb-2">Authentication failed</p>
            <p className="text-gray-400 text-sm">{error}</p>
          </div>
          <a
            href="/login"
            className="text-[#22d3ee] hover:text-[#06b6d4] font-medium transition-colors"
          >
            Back to login
          </a>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#0a0e27]">
      <div className="text-center">
        <LoadingSpinner size="lg" />
        <p className="text-gray-400 mt-4">Signing you in...</p>
      </div>
    </div>
  );
}
