import { useState, useEffect, Fragment } from 'react';
import { Dialog, Transition } from '@headlessui/react';
import { PlusIcon, XMarkIcon } from '@heroicons/react/24/outline';
import { Button } from '@components/common/Button';
import { LoadingSpinner } from '@components/common/LoadingSpinner';
import { InvestmentCard } from '@components/investment/InvestmentCard';
import { AddInvestmentModal } from '@components/investment/AddInvestmentModal';
import { PriceHistoryChart } from '@components/investment/PriceHistoryChart';
import { investmentsService } from '@services/investmentsService';
import type { Investment } from '@types/index';

export function Investments() {
  const [investments, setInvestments] = useState<Investment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [selectedInvestment, setSelectedInvestment] = useState<Investment | null>(null);

  useEffect(() => {
    fetchInvestments();
  }, []);

  const fetchInvestments = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await investmentsService.getUserInvestments({ active_only: true });
      setInvestments(data);
    } catch (err: any) {
      console.error('Failed to fetch investments:', err);
      setError('Failed to load investments');
    } finally {
      setLoading(false);
    }
  };

  const handleAddSuccess = () => {
    fetchInvestments();
  };

  const handleInvestmentClick = (investment: Investment) => {
    console.log('Clicked investment:', investment);
    setSelectedInvestment(investment);
  };

  const handleCloseDetail = () => {
    setSelectedInvestment(null);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2">Investments</h1>
          <p className="text-gray-400">
            {investments.length} {investments.length === 1 ? 'investment' : 'investments'}
          </p>
        </div>
        <Button variant="primary" onClick={() => setIsAddModalOpen(true)}>
          <PlusIcon className="w-5 h-5" />
          Add Investment
        </Button>
      </div>

      {error && (
        <div className="bg-[#ef4444]/10 border border-[#ef4444]/50 rounded-lg p-4 mb-6">
          <p className="text-[#ef4444]">{error}</p>
        </div>
      )}

      {investments.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16">
          <div className="bg-[#151932] border border-[#1f2544] rounded-full p-6 mb-4">
            <PlusIcon className="w-12 h-12 text-gray-400" />
          </div>
          <h3 className="text-xl font-semibold text-white mb-2">No investments yet</h3>
          <p className="text-gray-400 mb-6">Get started by adding your first investment</p>
          <Button variant="primary" onClick={() => setIsAddModalOpen(true)}>
            <PlusIcon className="w-5 h-5" />
            Add Investment
          </Button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {investments.map((investment) => (
            <InvestmentCard
              key={investment.id}
              investment={investment}
              onClick={() => handleInvestmentClick(investment)}
            />
          ))}
        </div>
      )}

      <AddInvestmentModal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
        onSuccess={handleAddSuccess}
      />

      {/* Investment Detail Modal */}
      <Transition appear show={!!selectedInvestment} as={Fragment}>
        <Dialog as="div" className="relative z-50" onClose={handleCloseDetail}>
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
                <Dialog.Panel className="w-full max-w-3xl transform overflow-hidden rounded-2xl bg-[#151932] border border-[#1f2544] p-6 shadow-xl transition-all">
                  {selectedInvestment && (
                    <>
                      <div className="flex items-center justify-between mb-6">
                        <div>
                          <Dialog.Title className="text-2xl font-bold text-white">
                            {selectedInvestment.symbol}
                          </Dialog.Title>
                          <p className="text-gray-400">{selectedInvestment.name}</p>
                        </div>
                        <button
                          onClick={handleCloseDetail}
                          className="text-gray-400 hover:text-gray-200 transition-colors"
                        >
                          <XMarkIcon className="w-6 h-6" />
                        </button>
                      </div>

                      <div className="mb-6">
                        <PriceHistoryChart
                          investmentId={selectedInvestment.id}
                          currency={selectedInvestment.currency}
                          purchaseDate={selectedInvestment.purchase_date}
                          purchasePrice={selectedInvestment.purchase_price}
                        />
                      </div>

                      <div className="grid grid-cols-2 gap-4 p-4 bg-[#0a0e27] rounded-lg">
                        <div>
                          <p className="text-sm text-gray-400">Asset Type</p>
                          <p className="text-base font-medium text-white capitalize">
                            {selectedInvestment.asset_type}
                          </p>
                        </div>
                        <div>
                          <p className="text-sm text-gray-400">Country</p>
                          <p className="text-base font-medium text-white">
                            {selectedInvestment.country}
                          </p>
                        </div>
                        {selectedInvestment.sector && (
                          <div>
                            <p className="text-sm text-gray-400">Sector</p>
                            <p className="text-base font-medium text-white">
                              {selectedInvestment.sector}
                            </p>
                          </div>
                        )}
                        {selectedInvestment.industry && (
                          <div>
                            <p className="text-sm text-gray-400">Industry</p>
                            <p className="text-base font-medium text-white">
                              {selectedInvestment.industry}
                            </p>
                          </div>
                        )}
                      </div>
                    </>
                  )}
                </Dialog.Panel>
              </Transition.Child>
            </div>
          </div>
        </Dialog>
      </Transition>
    </div>
  );
}
