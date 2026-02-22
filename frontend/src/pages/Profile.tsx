import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import {
  UserCircleIcon,
  EnvelopeIcon,
  PencilIcon,
  CheckIcon,
  XMarkIcon,
  GlobeAltIcon,
} from '@heroicons/react/24/outline';
import { Card } from '@components/common/Card';
import { Button } from '@components/common/Button';
import { LoadingSpinner } from '@components/common/LoadingSpinner';
import { useAuth } from '@hooks/useAuth';
import { usersService } from '@services/usersService';
import type { InvestmentProfileUpdate } from '@types/index';

const profileSchema = z.object({
  currency_preference: z.string().length(3, 'Currency must be 3 characters'),
  risk_tolerance: z.enum(['conservative', 'moderate', 'aggressive']),
  investment_horizon: z.string().optional(),
  country: z.string().max(3).optional(),
  ethical_exclusions: z.string().optional(),
  interests: z.string().optional(),
});

type ProfileFormData = z.infer<typeof profileSchema>;

const INVESTMENT_HORIZON_OPTIONS = [
  { value: 'short_term', label: 'Short term (< 2 years)' },
  { value: 'medium_term', label: 'Medium term (2–5 years)' },
  { value: 'medium_long_term', label: 'Medium to long term (5–10 years)' },
  { value: 'long_term', label: 'Long term (> 10 years)' },
];


const COUNTRY_OPTIONS = [
  { value: 'FRA', label: 'France' },
  { value: 'DEU', label: 'Germany' },
  { value: 'NLD', label: 'Netherlands' },
  { value: 'BEL', label: 'Belgium' },
  { value: 'ESP', label: 'Spain' },
  { value: 'ITA', label: 'Italy' },
  { value: 'CHE', label: 'Switzerland' },
  { value: 'LUX', label: 'Luxembourg' },
  { value: 'PRT', label: 'Portugal' },
  { value: 'SWE', label: 'Sweden' },
  { value: 'NOR', label: 'Norway' },
  { value: 'DNK', label: 'Denmark' },
  { value: 'AUT', label: 'Austria' },
  { value: 'FIN', label: 'Finland' },
  { value: 'GBR', label: 'United Kingdom' },
  { value: 'USA', label: 'United States' },
  { value: 'CAN', label: 'Canada' },
  { value: 'AUS', label: 'Australia' },
  { value: 'JPN', label: 'Japan' },
  { value: 'SGP', label: 'Singapore' },
];

const RISK_LABELS: Record<string, string> = {
  conservative: 'Conservative',
  moderate: 'Moderate',
  aggressive: 'Aggressive',
};

const SELECT_CLASS =
  'w-full px-4 py-2 bg-[#0a0e27] border border-[#1f2544] rounded-lg text-white focus:border-[#22d3ee] focus:ring-1 focus:ring-[#22d3ee] transition-colors';

const VIEW_FIELD_CLASS = 'bg-[#0a0e27] rounded-lg p-4 border border-[#1f2544]';

export function Profile() {
  const { user } = useAuth();
  const [isEditing, setIsEditing] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const storedProfile = usersService.getStoredInvestmentProfile();

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm<ProfileFormData>({
    resolver: zodResolver(profileSchema),
    defaultValues: {
      currency_preference: storedProfile?.currency_preference || 'EUR',
      risk_tolerance: storedProfile?.risk_tolerance || 'moderate',
      investment_horizon: storedProfile?.investment_horizon || '',
      country: storedProfile?.country || '',
      ethical_exclusions: storedProfile?.ethical_exclusions || '',
      interests: storedProfile?.interests || '',
    },
  });

  if (!user) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  const handleEdit = () => {
    const current = usersService.getStoredInvestmentProfile();
    setIsEditing(true);
    setError(null);
    setSuccess(null);
    reset({
      currency_preference: current?.currency_preference || 'EUR',
      risk_tolerance: current?.risk_tolerance || 'moderate',
      investment_horizon: current?.investment_horizon || '',
      country: current?.country || '',
      ethical_exclusions: current?.ethical_exclusions || '',
      interests: current?.interests || '',
    });
  };

  const handleCancel = () => {
    setIsEditing(false);
    setError(null);
    setSuccess(null);
    reset();
  };

  const onSubmit = async (data: ProfileFormData) => {
    setLoading(true);
    setError(null);
    setSuccess(null);
    try {
      const updateData: InvestmentProfileUpdate = {
        currency_preference: data.currency_preference,
        risk_tolerance: data.risk_tolerance,
        investment_horizon: data.investment_horizon || undefined,
        country: data.country || undefined,
        ethical_exclusions: data.ethical_exclusions || undefined,
        interests: data.interests || undefined,
      };
      await usersService.updateInvestmentProfile(updateData);
      setSuccess('Preferences updated successfully');
      setIsEditing(false);
    } catch (err: any) {
      console.error('Failed to update profile:', err);
      setError(err.response?.data?.detail || 'Failed to update preferences');
    } finally {
      setLoading(false);
    }
  };

  const currentProfile = usersService.getStoredInvestmentProfile();

  const horizonLabel = (value: string | null | undefined) =>
    INVESTMENT_HORIZON_OPTIONS.find(o => o.value === value)?.label ?? '—';

  const countryLabel = (value: string | null | undefined) =>
    COUNTRY_OPTIONS.find(o => o.value === value)?.label ?? value ?? '—';

  return (
    <div className="p-8 max-w-4xl mx-auto space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-white mb-2">Profile</h1>
        <p className="text-gray-400">Manage your account settings and investment preferences</p>
      </div>

      {success && (
        <div className="bg-[#10b981]/10 border border-[#10b981]/50 rounded-lg p-4">
          <p className="text-[#10b981]">{success}</p>
        </div>
      )}

      {error && (
        <div className="bg-[#ef4444]/10 border border-[#ef4444]/50 rounded-lg p-4">
          <p className="text-[#ef4444]">{error}</p>
        </div>
      )}

      {/* User Information (read-only) */}
      <Card>
        <div className="flex items-center gap-4 mb-6">
          {user.picture ? (
            <img src={user.picture} alt={user.name} className="w-16 h-16 rounded-full object-cover" />
          ) : (
            <div className="w-16 h-16 rounded-full bg-[#22d3ee]/10 flex items-center justify-center">
              <UserCircleIcon className="w-10 h-10 text-[#22d3ee]" />
            </div>
          )}
          <div>
            <h2 className="text-xl font-bold text-white">{user.name}</h2>
            <p className="text-sm text-gray-400 capitalize">{user.provider} account</p>
          </div>
        </div>
        <div className="flex items-start gap-4">
          <div className="w-10 h-10 rounded-full bg-[#a78bfa]/10 flex items-center justify-center flex-shrink-0">
            <EnvelopeIcon className="w-6 h-6 text-[#a78bfa]" />
          </div>
          <div>
            <p className="text-sm text-gray-400 mb-1">Email</p>
            <p className="text-base font-medium text-white">{user.email}</p>
          </div>
        </div>
      </Card>

      {/* Investment Preferences */}
      <Card>
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-bold text-white">Investment Preferences</h2>
          {!isEditing && (
            <Button variant="ghost" onClick={handleEdit}>
              <PencilIcon className="w-5 h-5" />
              Edit
            </Button>
          )}
        </div>

        {!isEditing ? (
          /* ── VIEW MODE ── */
          <div className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <p className="text-sm text-gray-400 mb-2">Currency</p>
                <div className={VIEW_FIELD_CLASS}>
                  <p className="text-base font-medium text-white">
                    {currentProfile?.currency_preference || 'EUR'}
                  </p>
                </div>
              </div>

              <div>
                <p className="text-sm text-gray-400 mb-2">Risk Tolerance</p>
                <div className={VIEW_FIELD_CLASS}>
                  <p className="text-base font-medium text-white capitalize">
                    {RISK_LABELS[currentProfile?.risk_tolerance || 'moderate']}
                  </p>
                </div>
              </div>

              <div>
                <p className="text-sm text-gray-400 mb-2">Investment Horizon</p>
                <div className={VIEW_FIELD_CLASS}>
                  <p className="text-base font-medium text-white">
                    {horizonLabel(currentProfile?.investment_horizon)}
                  </p>
                </div>
              </div>

              <div>
                <p className="text-sm text-gray-400 mb-2">Country</p>
                <div className={VIEW_FIELD_CLASS}>
                  <p className="text-base font-medium text-white">
                    {countryLabel(currentProfile?.country)}
                  </p>
                </div>
              </div>
            </div>

            <div>
              <p className="text-sm text-gray-400 mb-2">Ethical Exclusions</p>
              <div className={VIEW_FIELD_CLASS}>
                {currentProfile?.ethical_exclusions ? (
                  <p className="text-sm text-white whitespace-pre-wrap">{currentProfile.ethical_exclusions}</p>
                ) : (
                  <p className="text-base font-medium text-gray-500">—</p>
                )}
              </div>
            </div>

            <div>
              <p className="text-sm text-gray-400 mb-2">Investment Interests</p>
              <div className={VIEW_FIELD_CLASS}>
                {currentProfile?.interests ? (
                  <p className="text-sm text-white whitespace-pre-wrap">{currentProfile.interests}</p>
                ) : (
                  <p className="text-base font-medium text-gray-500">—</p>
                )}
              </div>
            </div>
          </div>
        ) : (
          /* ── EDIT MODE ── */
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Currency */}
              <div>
                <label htmlFor="currency_preference" className="block text-sm font-medium text-gray-200 mb-2">
                  Currency
                </label>
                <select id="currency_preference" {...register('currency_preference')} className={SELECT_CLASS}>
                  <option value="USD">USD — US Dollar</option>
                  <option value="EUR">EUR — Euro</option>
                  <option value="GBP">GBP — British Pound</option>
                  <option value="JPY">JPY — Japanese Yen</option>
                  <option value="CAD">CAD — Canadian Dollar</option>
                  <option value="AUD">AUD — Australian Dollar</option>
                </select>
                {errors.currency_preference && (
                  <p className="mt-1 text-sm text-[#ef4444]">{errors.currency_preference.message}</p>
                )}
              </div>

              {/* Risk Tolerance */}
              <div>
                <label htmlFor="risk_tolerance" className="block text-sm font-medium text-gray-200 mb-2">
                  Risk Tolerance
                </label>
                <select id="risk_tolerance" {...register('risk_tolerance')} className={SELECT_CLASS}>
                  <option value="conservative">Conservative — Prefer stability</option>
                  <option value="moderate">Moderate — Balanced risk and reward</option>
                  <option value="aggressive">Aggressive — Seek higher returns</option>
                </select>
                {errors.risk_tolerance && (
                  <p className="mt-1 text-sm text-[#ef4444]">{errors.risk_tolerance.message}</p>
                )}
              </div>

              {/* Investment Horizon */}
              <div>
                <label htmlFor="investment_horizon" className="block text-sm font-medium text-gray-200 mb-2">
                  Investment Horizon
                </label>
                <select id="investment_horizon" {...register('investment_horizon')} className={SELECT_CLASS}>
                  <option value="">Select horizon…</option>
                  {INVESTMENT_HORIZON_OPTIONS.map(o => (
                    <option key={o.value} value={o.value}>{o.label}</option>
                  ))}
                </select>
              </div>

              {/* Country */}
              <div>
                <label htmlFor="country" className="block text-sm font-medium text-gray-200 mb-2">
                  Country
                </label>
                <select id="country" {...register('country')} className={SELECT_CLASS}>
                  <option value="">Select country…</option>
                  {COUNTRY_OPTIONS.map(o => (
                    <option key={o.value} value={o.value}>{o.label}</option>
                  ))}
                </select>
              </div>
            </div>

            {/* Ethical Exclusions */}
            <div>
              <label htmlFor="ethical_exclusions" className="block text-sm font-medium text-gray-200 mb-1">
                Ethical Exclusions
              </label>
              <p className="text-xs text-gray-500 mb-2">Sectors always excluded from AI recommendations</p>
              <textarea
                id="ethical_exclusions"
                {...register('ethical_exclusions')}
                rows={3}
                placeholder="e.g. No defense companies, no fossil fuels, no tobacco or gambling"
                className="w-full px-4 py-3 bg-[#0a0e27] border border-[#1f2544] rounded-lg text-white placeholder-gray-600 focus:border-[#22d3ee] focus:ring-1 focus:ring-[#22d3ee] transition-colors resize-none"
              />
            </div>

            {/* Investment Interests */}
            <div>
              <label htmlFor="interests" className="block text-sm font-medium text-gray-200 mb-1">
                Investment Interests
              </label>
              <p className="text-xs text-gray-500 mb-2">Themes and sectors to prioritize in AI recommendations</p>
              <textarea
                id="interests"
                {...register('interests')}
                rows={3}
                placeholder="e.g. AI, semiconductors, renewable energy, healthcare"
                className="w-full px-4 py-3 bg-[#0a0e27] border border-[#1f2544] rounded-lg text-white placeholder-gray-600 focus:border-[#22d3ee] focus:ring-1 focus:ring-[#22d3ee] transition-colors resize-none"
              />
            </div>

            <div className="flex gap-4 pt-2">
              <Button type="submit" variant="primary" loading={loading} disabled={loading} className="flex-1">
                <CheckIcon className="w-5 h-5" />
                Save Changes
              </Button>
              <Button type="button" variant="secondary" onClick={handleCancel} disabled={loading} className="flex-1">
                <XMarkIcon className="w-5 h-5" />
                Cancel
              </Button>
            </div>
          </form>
        )}
      </Card>

      {/* Last Macro Context (read-only, set by AI agent) */}
      {currentProfile?.last_macro_context && (
        <Card>
          <div className="flex items-center gap-3 mb-4">
            <div className="w-8 h-8 rounded-full bg-[#a78bfa]/10 flex items-center justify-center flex-shrink-0">
              <GlobeAltIcon className="w-5 h-5 text-[#a78bfa]" />
            </div>
            <div>
              <h2 className="text-base font-semibold text-white">Last Macro Context</h2>
              <p className="text-xs text-gray-500">Set automatically by the AI agent during the last analysis</p>
            </div>
          </div>
          <p className="text-sm text-gray-300 leading-relaxed">{currentProfile.last_macro_context}</p>
        </Card>
      )}
    </div>
  );
}
