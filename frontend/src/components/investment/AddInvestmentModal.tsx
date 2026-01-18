import { Fragment, useState } from 'react';
import { Dialog, Transition } from '@headlessui/react';
import { XMarkIcon } from '@heroicons/react/24/outline';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@components/common/Button';
import { Input } from '@components/common/Input';
import { investmentsService } from '@services/investmentsService';
import type { InvestmentCreate } from '@types/index';

interface AddInvestmentModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

const investmentSchema = z.object({
  ticker_symbol: z
    .string()
    .min(1, 'Ticker symbol is required')
    .max(10, 'Ticker symbol too long')
    .transform((val) => val.toUpperCase()),
  purchase_date: z.string().min(1, 'Purchase date is required'),
  quantity: z
    .number({ invalid_type_error: 'Quantity must be a number' })
    .positive('Quantity must be positive')
    .min(0.00001, 'Quantity must be greater than 0'),
});

type InvestmentFormData = z.infer<typeof investmentSchema>;

export function AddInvestmentModal({ isOpen, onClose, onSuccess }: AddInvestmentModalProps) {
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm<InvestmentFormData>({
    resolver: zodResolver(investmentSchema),
  });

  const handleClose = () => {
    reset();
    setError(null);
    onClose();
  };

  const onSubmit = async (data: InvestmentFormData) => {
    setError(null);
    setIsSubmitting(true);

    try {
      const createData: InvestmentCreate = {
        ticker_symbol: data.ticker_symbol,
        purchase_date: data.purchase_date,
        quantity: data.quantity,
      };

      await investmentsService.createInvestment(createData);
      handleClose();
      onSuccess();
    } catch (err: any) {
      console.error('Failed to create investment:', err);
      setError(
        err.response?.data?.detail ||
          'Failed to create investment. Please check the ticker symbol and try again.'
      );
    } finally {
      setIsSubmitting(false);
    }
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

                <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                  {error && (
                    <div className="bg-[#ef4444]/10 border border-[#ef4444]/50 rounded-lg p-3">
                      <p className="text-[#ef4444] text-sm">{error}</p>
                    </div>
                  )}

                  <Input
                    {...register('ticker_symbol')}
                    label="Ticker Symbol"
                    placeholder="e.g., AAPL, GOOGL"
                    error={errors.ticker_symbol?.message}
                    disabled={isSubmitting}
                    required
                    className="uppercase"
                  />

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
