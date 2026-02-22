import { Fragment, useState, useEffect } from 'react';
import { Dialog, Transition } from '@headlessui/react';
import { XMarkIcon, ChevronDownIcon, ChevronRightIcon } from '@heroicons/react/24/outline';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@components/common/Button';
import { Input } from '@components/common/Input';
import { investmentsService } from '@services/investmentsService';
import type { InvestmentCreate, InvestmentInitialValues } from '@types/index';

interface AddInvestmentModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  initialValues?: InvestmentInitialValues;
}

const investmentSchema = z
  .object({
    account_type: z.enum(['CTO', 'PEA']),
    ticker_symbol: z.preprocess(
      (val) => {
        if (typeof val !== 'string') return val;
        const trimmed = val.trim();
        return trimmed ? trimmed.toUpperCase() : undefined;
      },
      z.string().min(1, 'Ticker symbol is required').max(10, 'Ticker symbol too long').optional()
    ),
    isin: z.preprocess(
      (val) => {
        if (typeof val !== 'string') return val;
        const trimmed = val.trim();
        return trimmed ? trimmed.toUpperCase() : undefined;
      },
      z
        .string()
        .length(12, 'ISIN must be 12 characters')
        .regex(/^[A-Z0-9]+$/, 'ISIN must be alphanumeric')
        .optional()
    ),
    purchase_date: z.string().min(1, 'Purchase date is required'),
    quantity: z
      .number({ invalid_type_error: 'Quantity must be a number' })
      .positive('Quantity must be positive')
      .min(0.00001, 'Quantity must be greater than 0'),
    // Optional fields
    notes: z.preprocess(
      (val) => (typeof val === 'string' && val.trim() === '' ? undefined : val),
      z.string().optional()
    ),
    investment_thesis: z.preprocess(
      (val) => (typeof val === 'string' && val.trim() === '' ? undefined : val),
      z.string().optional()
    ),
    thesis_status: z.preprocess(
      (val) => (val === '' ? undefined : val),
      z.enum(['valid', 'watch', 'reconsider']).optional()
    ),
    alert_threshold_pct: z.preprocess(
      (val) => {
        if (val === '' || val === undefined || val === null) return undefined;
        const n = Number(val);
        return isNaN(n) ? undefined : n;
      },
      z.number().optional()
    ),
  })
  .superRefine((data, ctx) => {
    if (data.account_type === 'PEA' && !data.ticker_symbol) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Ticker symbol is required for PEA',
        path: ['ticker_symbol'],
      });
    }
    if (data.account_type === 'CTO' && !data.isin) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'ISIN is required for CTO',
        path: ['isin'],
      });
    }
  });

type InvestmentFormData = z.infer<typeof investmentSchema>;

export function AddInvestmentModal({ isOpen, onClose, onSuccess, initialValues }: AddInvestmentModalProps) {
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showOptional, setShowOptional] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
    watch,
  } = useForm<InvestmentFormData>({
    resolver: zodResolver(investmentSchema),
    defaultValues: {
      account_type: 'PEA',
    },
    shouldUnregister: true,
  });
  const accountType = watch('account_type');

  // Pre-fill form whenever the modal opens (with or without initial values)
  useEffect(() => {
    if (!isOpen) return;
    const today = new Date().toISOString().split('T')[0];
    const defaults: Partial<InvestmentFormData> = {
      account_type: initialValues?.account_type ?? 'PEA',
      purchase_date: today,
    };
    if (initialValues?.ticker_symbol) {
      if (initialValues.account_type !== 'CTO') {
        defaults.ticker_symbol = initialValues.ticker_symbol;
      }
      // For CTO accounts the agent provides a ticker but the form needs an ISIN.
      // We still set notes below — the ticker will appear there as a reference.
    }
    if (initialValues?.suggested_quantity != null) {
      defaults.quantity = initialValues.suggested_quantity;
    }
    if (initialValues?.investment_thesis) {
      defaults.investment_thesis = initialValues.investment_thesis;
    }
    // Build notes: combine agent notes with CTO ticker reference if needed
    const agentNotes = initialValues?.notes ?? '';
    const ctoPart =
      initialValues?.account_type === 'CTO' && initialValues?.ticker_symbol
        ? `Ticker de référence : ${initialValues.ticker_symbol}.`
        : '';
    const combinedNotes = [ctoPart, agentNotes].filter(Boolean).join('\n').trim();
    if (combinedNotes) {
      defaults.notes = combinedNotes;
    }
    if (initialValues?.alert_threshold_pct != null) {
      defaults.alert_threshold_pct = initialValues.alert_threshold_pct;
    }
    reset(defaults);
    setShowOptional(!!(initialValues?.investment_thesis || combinedNotes || initialValues?.alert_threshold_pct != null));
    setError(null);
  }, [isOpen]); // eslint-disable-line react-hooks/exhaustive-deps

  const handleClose = () => {
    reset();
    setError(null);
    setShowOptional(false);
    onClose();
  };

  const onSubmit = async (data: InvestmentFormData) => {
    setError(null);
    setIsSubmitting(true);

    try {
      const createData: InvestmentCreate = {
        account_type: data.account_type,
        purchase_date: data.purchase_date,
        quantity: data.quantity,
        ...(data.account_type === 'PEA'
          ? { ticker_symbol: data.ticker_symbol }
          : { isin: data.isin }),
        ...(data.notes && { notes: data.notes }),
        ...(data.investment_thesis && { investment_thesis: data.investment_thesis }),
        ...(data.thesis_status && { thesis_status: data.thesis_status }),
        ...(data.alert_threshold_pct !== undefined && { alert_threshold_pct: data.alert_threshold_pct }),
      };

      await investmentsService.createInvestment(createData);
      handleClose();
      onSuccess();
    } catch (err: any) {
      console.error('Failed to create investment:', err);
      setError(
        err.response?.data?.detail ||
          'Failed to create investment. Please check the ticker symbol or ISIN and try again.'
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  const onInvalid = () => {
    setError('Please fix the highlighted fields and try again.');
  };

  const thesisStatusColors: Record<string, string> = {
    valid: 'text-[#10b981]',
    watch: 'text-[#f59e0b]',
    reconsider: 'text-[#ef4444]',
  };

  return (
    <Transition appear show={isOpen} as={Fragment}>
      <Dialog as="div" className="relative z-50" onClose={handleClose}>
        <Transition.Child
          as={Fragment}
          enter="ease-out duration-300"
          enterFrom="opacity-0"
          enterTo="opacity-100"
          leave="ease-in duration-200"
          leaveFrom="opacity-100"
          leaveTo="opacity-0"
        >
          <div className="fixed inset-0 bg-black/75 backdrop-blur-sm" />
        </Transition.Child>

        <div className="fixed inset-0 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <Transition.Child
              as={Fragment}
              enter="ease-out duration-300"
              enterFrom="opacity-0 scale-95"
              enterTo="opacity-100 scale-100"
              leave="ease-in duration-200"
              leaveFrom="opacity-100 scale-100"
              leaveTo="opacity-0 scale-95"
            >
              <Dialog.Panel className="w-full max-w-md transform overflow-hidden rounded-2xl bg-[#151932] border border-[#1f2544] p-6 shadow-xl transition-all">
                <div className="flex items-center justify-between mb-4">
                  <Dialog.Title className="text-xl font-bold text-white">
                    Add Investment
                  </Dialog.Title>
                  <button
                    onClick={handleClose}
                    className="text-gray-400 hover:text-gray-200 transition-colors"
                  >
                    <XMarkIcon className="w-6 h-6" />
                  </button>
                </div>

                <form
                  onSubmit={handleSubmit(onSubmit, onInvalid)}
                  className="space-y-4"
                  noValidate
                >
                  {error && (
                    <div className="bg-[#ef4444]/10 border border-[#ef4444]/50 rounded-lg p-3">
                      <p className="text-[#ef4444] text-sm">{error}</p>
                    </div>
                  )}

                  {/* Account Type */}
                  <div className="w-full">
                    <label className="block text-sm font-medium text-gray-300 mb-2">
                      Account Type<span className="text-[#ef4444] ml-1">*</span>
                    </label>
                    <select
                      {...register('account_type')}
                      disabled={isSubmitting}
                      className="w-full px-4 py-2 bg-[#0a0e27] border border-[#1f2544] rounded-lg text-gray-200 transition-colors focus:outline-none focus:ring-2 focus:ring-[#22d3ee] focus:ring-offset-2 focus:ring-offset-[#151932] disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      <option value="PEA">PEA</option>
                      <option value="CTO">CTO</option>
                    </select>
                    {errors.account_type?.message && (
                      <p className="mt-1.5 text-sm text-[#ef4444]">{errors.account_type.message}</p>
                    )}
                  </div>

                  {/* Ticker / ISIN */}
                  {accountType === 'PEA' ? (
                    <Input
                      {...register('ticker_symbol')}
                      label="Ticker Symbol"
                      placeholder="e.g., AAPL, GOOGL"
                      error={errors.ticker_symbol?.message}
                      disabled={isSubmitting}
                      required
                      className="uppercase"
                    />
                  ) : (
                    <Input
                      {...register('isin')}
                      label="ISIN"
                      placeholder="e.g., US0378331005"
                      error={errors.isin?.message}
                      disabled={isSubmitting}
                      required
                      className="uppercase"
                      helperText="12-character alphanumeric code"
                    />
                  )}

                  <Input
                    {...register('quantity', { valueAsNumber: true })}
                    label="Quantity"
                    type="number"
                    step="0.00001"
                    placeholder="e.g., 10"
                    error={errors.quantity?.message}
                    disabled={isSubmitting}
                    required
                  />

                  <Input
                    {...register('purchase_date')}
                    label="Purchase Date"
                    type="date"
                    error={errors.purchase_date?.message}
                    disabled={isSubmitting}
                    required
                  />

                  {/* Optional fields toggle */}
                  <button
                    type="button"
                    onClick={() => setShowOptional(v => !v)}
                    className="w-full flex items-center gap-2 text-sm text-gray-400 hover:text-gray-200 transition-colors py-1"
                  >
                    {showOptional ? (
                      <ChevronDownIcon className="w-4 h-4" />
                    ) : (
                      <ChevronRightIcon className="w-4 h-4" />
                    )}
                    Optional details
                  </button>

                  {showOptional && (
                    <div className="space-y-4 border-l-2 border-[#1f2544] pl-4">
                      {/* Notes */}
                      <div>
                        <label className="block text-sm font-medium text-gray-300 mb-2">Notes</label>
                        <textarea
                          {...register('notes')}
                          disabled={isSubmitting}
                          rows={2}
                          placeholder="Any personal notes about this investment…"
                          className="w-full px-4 py-2 bg-[#0a0e27] border border-[#1f2544] rounded-lg text-gray-200 text-sm resize-none focus:outline-none focus:ring-2 focus:ring-[#22d3ee] focus:ring-offset-2 focus:ring-offset-[#151932] disabled:opacity-50 placeholder:text-gray-600"
                        />
                      </div>

                      {/* Investment Thesis */}
                      <div>
                        <label className="block text-sm font-medium text-gray-300 mb-2">
                          Investment Thesis
                        </label>
                        <textarea
                          {...register('investment_thesis')}
                          disabled={isSubmitting}
                          rows={3}
                          placeholder="Why are you investing in this asset?"
                          className="w-full px-4 py-2 bg-[#0a0e27] border border-[#1f2544] rounded-lg text-gray-200 text-sm resize-none focus:outline-none focus:ring-2 focus:ring-[#22d3ee] focus:ring-offset-2 focus:ring-offset-[#151932] disabled:opacity-50 placeholder:text-gray-600"
                        />
                      </div>

                      {/* Thesis Status */}
                      <div>
                        <label className="block text-sm font-medium text-gray-300 mb-2">
                          Thesis Status
                        </label>
                        <select
                          {...register('thesis_status')}
                          disabled={isSubmitting}
                          className="w-full px-4 py-2 bg-[#0a0e27] border border-[#1f2544] rounded-lg text-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-[#22d3ee] focus:ring-offset-2 focus:ring-offset-[#151932] disabled:opacity-50"
                        >
                          <option value="">— none —</option>
                          <option value="valid" className={thesisStatusColors.valid}>Valid</option>
                          <option value="watch" className={thesisStatusColors.watch}>Watch</option>
                          <option value="reconsider" className={thesisStatusColors.reconsider}>Reconsider</option>
                        </select>
                      </div>

                      {/* Alert Threshold */}
                      <div>
                        <label className="block text-sm font-medium text-gray-300 mb-2">
                          Alert Threshold (%)
                        </label>
                        <input
                          {...register('alert_threshold_pct')}
                          type="number"
                          step="0.1"
                          disabled={isSubmitting}
                          placeholder="e.g., -20"
                          className="w-full px-4 py-2 bg-[#0a0e27] border border-[#1f2544] rounded-lg text-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-[#22d3ee] focus:ring-offset-2 focus:ring-offset-[#151932] disabled:opacity-50 placeholder:text-gray-600"
                        />
                        <p className="mt-1 text-xs text-gray-500">
                          Alert when price drops below this % from purchase price (e.g., -20)
                        </p>
                      </div>
                    </div>
                  )}

                  <div className="flex gap-3 pt-4">
                    <Button
                      type="button"
                      variant="secondary"
                      onClick={handleClose}
                      disabled={isSubmitting}
                      className="flex-1"
                    >
                      Cancel
                    </Button>
                    <Button type="submit" variant="primary" loading={isSubmitting} className="flex-1">
                      Add Investment
                    </Button>
                  </div>
                </form>

                <p className="mt-4 text-xs text-gray-400 text-center">
                  Investment data will be fetched from Yahoo Finance
                </p>
              </Dialog.Panel>
            </Transition.Child>
          </div>
        </div>
      </Dialog>
    </Transition>
  );
}
