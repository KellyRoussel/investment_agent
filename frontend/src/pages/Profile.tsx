import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import {
  UserCircleIcon,
  EnvelopeIcon,
  ClockIcon,
  CheckCircleIcon,
  PencilIcon,
  CheckIcon,
  XMarkIcon,
} from '@heroicons/react/24/outline';
import { Card } from '@components/common/Card';
import { Button } from '@components/common/Button';
import { Input } from '@components/common/Input';
import { LoadingSpinner } from '@components/common/LoadingSpinner';
import { useAuth } from '@hooks/useAuth';
import { usersService } from '@services/usersService';
import { formatDate } from '@utils/formatters';
import type { UserUpdate } from '@types/index';

const userUpdateSchema = z.object({
  full_name: z.string().min(1, 'Full name is required').max(255),
  email: z.string().email('Invalid email address').max(255),
  currency_preference: z.string().length(3, 'Currency must be 3 characters'),
  risk_tolerance: z.enum(['conservative', 'moderate', 'aggressive']),
});

type UserUpdateForm = z.infer<typeof userUpdateSchema>;

export function Profile() {
  const { user, refreshUser } = useAuth();
  const [isEditing, setIsEditing] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm<UserUpdateForm>({
    resolver: zodResolver(userUpdateSchema),
    defaultValues: {
      full_name: user?.full_name || '',
      email: user?.email || '',
      currency_preference: user?.currency_preference || 'USD',
      risk_tolerance: user?.risk_tolerance || 'moderate',
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
    setIsEditing(true);
    setError(null);
    setSuccess(null);
    reset({
      full_name: user.full_name,
      email: user.email,
      currency_preference: user.currency_preference,
      risk_tolerance: user.risk_tolerance,
    });
  };

  const handleCancel = () => {
    setIsEditing(false);
    setError(null);
    setSuccess(null);
    reset();
  };

  const onSubmit = async (data: UserUpdateForm) => {
    setLoading(true);
    setError(null);
    setSuccess(null);

    try {
      const updateData: UserUpdate = {};

      // Only include changed fields
      if (data.full_name !== user.full_name) updateData.full_name = data.full_name;
      if (data.email !== user.email) updateData.email = data.email;
      if (data.currency_preference !== user.currency_preference) {
        updateData.currency_preference = data.currency_preference;
      }
      if (data.risk_tolerance !== user.risk_tolerance) {
        updateData.risk_tolerance = data.risk_tolerance;
      }

      if (Object.keys(updateData).length === 0) {
        setSuccess('No changes to save');
        setIsEditing(false);
        return;
      }

      await usersService.updateUser(user.id, updateData);
      await refreshUser();
      setSuccess('Profile updated successfully');
      setIsEditing(false);
    } catch (err: any) {
      console.error('Failed to update profile:', err);
      setError(err.response?.data?.detail || 'Failed to update profile');
    } finally {
      setLoading(false);
    }
  };

  const riskToleranceLabels = {
    conservative: 'Conservative',
    moderate: 'Moderate',
    aggressive: 'Aggressive',
  };

  return (
    <div className="p-8 max-w-4xl mx-auto space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-white mb-2">Profile</h1>
        <p className="text-gray-400">Manage your account settings and preferences</p>
      </div>

      {/* Success Message */}
      {success && (
        <div className="bg-[#10b981]/10 border border-[#10b981]/50 rounded-lg p-4">
          <p className="text-[#10b981]">{success}</p>
        </div>
      )}

      {/* Error Message */}
      {error && (
        <div className="bg-[#ef4444]/10 border border-[#ef4444]/50 rounded-lg p-4">
          <p className="text-[#ef4444]">{error}</p>
        </div>
      )}

      {/* User Information Card */}
      <Card>
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-bold text-white">User Information</h2>
          {!isEditing && (
            <Button variant="ghost" onClick={handleEdit}>
              <PencilIcon className="w-5 h-5" />
              Edit
            </Button>
          )}
        </div>

        {!isEditing ? (
          <div className="space-y-6">
            {/* Full Name */}
            <div className="flex items-start gap-4">
              <div className="w-10 h-10 rounded-full bg-[#22d3ee]/10 flex items-center justify-center flex-shrink-0">
                <UserCircleIcon className="w-6 h-6 text-[#22d3ee]" />
              </div>
              <div>
                <p className="text-sm text-gray-400 mb-1">Full Name</p>
                <p className="text-base font-medium text-white">{user.full_name}</p>
              </div>
            </div>

            {/* Email */}
            <div className="flex items-start gap-4">
              <div className="w-10 h-10 rounded-full bg-[#a78bfa]/10 flex items-center justify-center flex-shrink-0">
                <EnvelopeIcon className="w-6 h-6 text-[#a78bfa]" />
              </div>
              <div className="flex-1">
                <p className="text-sm text-gray-400 mb-1">Email</p>
                <div className="flex items-center gap-2">
                  <p className="text-base font-medium text-white">{user.email}</p>
                  {user.email_verified && (
                    <span className="flex items-center gap-1 text-xs text-[#10b981] bg-[#10b981]/10 px-2 py-1 rounded">
                      <CheckCircleIcon className="w-3 h-3" />
                      Verified
                    </span>
                  )}
                </div>
              </div>
            </div>

            {/* Last Login */}
            {user.last_login && (
              <div className="flex items-start gap-4">
                <div className="w-10 h-10 rounded-full bg-[#f472b6]/10 flex items-center justify-center flex-shrink-0">
                  <ClockIcon className="w-6 h-6 text-[#f472b6]" />
                </div>
                <div>
                  <p className="text-sm text-gray-400 mb-1">Last Login</p>
                  <p className="text-base font-medium text-white">
                    {formatDate(user.last_login)}
                  </p>
                </div>
              </div>
            )}

            {/* Account Created */}
            <div className="flex items-start gap-4">
              <div className="w-10 h-10 rounded-full bg-[#10b981]/10 flex items-center justify-center flex-shrink-0">
                <CheckCircleIcon className="w-6 h-6 text-[#10b981]" />
              </div>
              <div>
                <p className="text-sm text-gray-400 mb-1">Account Created</p>
                <p className="text-base font-medium text-white">{formatDate(user.created_at)}</p>
              </div>
            </div>
          </div>
        ) : (
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
            <Input
              label="Full Name"
              {...register('full_name')}
              error={errors.full_name?.message}
              placeholder="John Doe"
            />

            <Input
              label="Email"
              type="email"
              {...register('email')}
              error={errors.email?.message}
              placeholder="john@example.com"
            />

            <div className="flex gap-4">
              <Button
                type="submit"
                variant="primary"
                loading={loading}
                disabled={loading}
                className="flex-1"
              >
                <CheckIcon className="w-5 h-5" />
                Save Changes
              </Button>
              <Button
                type="button"
                variant="secondary"
                onClick={handleCancel}
                disabled={loading}
                className="flex-1"
              >
                <XMarkIcon className="w-5 h-5" />
                Cancel
              </Button>
            </div>
          </form>
        )}
      </Card>

      {/* Preferences Card */}
      <Card>
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-bold text-white">Preferences</h2>
          {!isEditing && (
            <Button variant="ghost" onClick={handleEdit}>
              <PencilIcon className="w-5 h-5" />
              Edit
            </Button>
          )}
        </div>

        {!isEditing ? (
          <div className="space-y-6">
            {/* Currency Preference */}
            <div>
              <p className="text-sm text-gray-400 mb-2">Currency Preference</p>
              <div className="bg-[#0a0e27] rounded-lg p-4 border border-[#1f2544]">
                <p className="text-base font-medium text-white">{user.currency_preference}</p>
              </div>
            </div>

            {/* Risk Tolerance */}
            <div>
              <p className="text-sm text-gray-400 mb-2">Risk Tolerance</p>
              <div className="bg-[#0a0e27] rounded-lg p-4 border border-[#1f2544]">
                <p className="text-base font-medium text-white capitalize">
                  {riskToleranceLabels[user.risk_tolerance]}
                </p>
              </div>
            </div>
          </div>
        ) : (
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
            <div>
              <label htmlFor="currency_preference" className="block text-sm font-medium text-gray-200 mb-2">
                Currency Preference
              </label>
              <select
                id="currency_preference"
                {...register('currency_preference')}
                className="w-full px-4 py-2 bg-[#0a0e27] border border-[#1f2544] rounded-lg text-white focus:border-[#22d3ee] focus:ring-1 focus:ring-[#22d3ee] transition-colors"
              >
                <option value="USD">USD - US Dollar</option>
                <option value="EUR">EUR - Euro</option>
                <option value="GBP">GBP - British Pound</option>
                <option value="JPY">JPY - Japanese Yen</option>
                <option value="CAD">CAD - Canadian Dollar</option>
                <option value="AUD">AUD - Australian Dollar</option>
              </select>
              {errors.currency_preference && (
                <p className="mt-1 text-sm text-[#ef4444]">{errors.currency_preference.message}</p>
              )}
            </div>

            <div>
              <label htmlFor="risk_tolerance" className="block text-sm font-medium text-gray-200 mb-2">
                Risk Tolerance
              </label>
              <select
                id="risk_tolerance"
                {...register('risk_tolerance')}
                className="w-full px-4 py-2 bg-[#0a0e27] border border-[#1f2544] rounded-lg text-white focus:border-[#22d3ee] focus:ring-1 focus:ring-[#22d3ee] transition-colors"
              >
                <option value="conservative">Conservative - Prefer stability and lower risk</option>
                <option value="moderate">Moderate - Balanced risk and reward</option>
                <option value="aggressive">Aggressive - Seek higher returns, accept higher risk</option>
              </select>
              {errors.risk_tolerance && (
                <p className="mt-1 text-sm text-[#ef4444]">{errors.risk_tolerance.message}</p>
              )}
            </div>

            <div className="flex gap-4">
              <Button
                type="submit"
                variant="primary"
                loading={loading}
                disabled={loading}
                className="flex-1"
              >
                <CheckIcon className="w-5 h-5" />
                Save Changes
              </Button>
              <Button
                type="button"
                variant="secondary"
                onClick={handleCancel}
                disabled={loading}
                className="flex-1"
              >
                <XMarkIcon className="w-5 h-5" />
                Cancel
              </Button>
            </div>
          </form>
        )}
      </Card>
    </div>
  );
}
