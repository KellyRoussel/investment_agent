import { useState, useEffect, Fragment } from 'react';
import { Dialog, Transition } from '@headlessui/react';
import { PlusIcon, XMarkIcon, SparklesIcon, UserIcon, TrashIcon } from '@heroicons/react/24/outline';
import { EyeIcon } from '@heroicons/react/24/outline';
import { Button } from '@components/common/Button';
import { LoadingSpinner } from '@components/common/LoadingSpinner';
import { watchlistService } from '@services/watchlistService';
import type { WatchlistItem, WatchlistItemCreate } from '@types/index';
import { format } from 'date-fns';

const PRIORITY_CONFIG = {
  high: { label: 'High', color: 'text-[#ef4444]', bg: 'bg-[#ef4444]/10', border: 'border-[#ef4444]/30', dot: 'bg-[#ef4444]' },
  normal: { label: 'Normal', color: 'text-[#22d3ee]', bg: 'bg-[#22d3ee]/10', border: 'border-[#22d3ee]/30', dot: 'bg-[#22d3ee]' },
  low: { label: 'Low', color: 'text-gray-400', bg: 'bg-gray-400/10', border: 'border-gray-400/30', dot: 'bg-gray-400' },
};

const PRIORITY_ORDER = ['high', 'normal', 'low'] as const;

function PriorityBadge({ priority }: { priority: string | null }) {
  const key = (priority ?? 'normal') as keyof typeof PRIORITY_CONFIG;
  const cfg = PRIORITY_CONFIG[key] ?? PRIORITY_CONFIG.normal;
  return (
    <span className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-medium ${cfg.bg} ${cfg.color} border ${cfg.border}`}>
      <span className={`w-1.5 h-1.5 rounded-full ${cfg.dot}`} />
      {cfg.label}
    </span>
  );
}

function SourceBadge({ source }: { source: string | null }) {
  const isAgent = source === 'agent_suggestion';
  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${
      isAgent
        ? 'bg-[#a78bfa]/10 text-[#a78bfa] border border-[#a78bfa]/30'
        : 'bg-gray-400/10 text-gray-400 border border-gray-400/20'
    }`}>
      {isAgent ? <SparklesIcon className="w-3 h-3" /> : <UserIcon className="w-3 h-3" />}
      {isAgent ? 'AI suggested' : 'Manual'}
    </span>
  );
}

interface AddItemModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

function AddItemModal({ isOpen, onClose, onSuccess }: AddItemModalProps) {
  const [form, setForm] = useState<WatchlistItemCreate>({
    name: '',
    symbol: '',
    sector: '',
    country: '',
    reason: '',
    priority: 'normal',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    setForm(prev => ({ ...prev, [e.target.name]: e.target.value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const payload: WatchlistItemCreate = {
        name: form.name.trim(),
        symbol: form.symbol?.trim() || undefined,
        sector: form.sector?.trim() || undefined,
        country: form.country?.trim() || undefined,
        reason: form.reason?.trim() || undefined,
        priority: form.priority,
      };
      await watchlistService.addItem(payload);
      setForm({ name: '', symbol: '', sector: '', country: '', reason: '', priority: 'normal' });
      onSuccess();
      onClose();
    } catch {
      setError('Failed to add item. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const inputClass = "w-full bg-[#0a0e27] border border-[#1f2544] rounded-lg px-3 py-2 text-white placeholder-gray-500 focus:outline-none focus:border-[#22d3ee] transition-colors text-sm";
  const labelClass = "block text-sm text-gray-400 mb-1";

  return (
    <Transition appear show={isOpen} as={Fragment}>
      <Dialog as="div" className="relative z-50" onClose={onClose}>
        <Transition.Child
          as={Fragment}
          enter="ease-out duration-300" enterFrom="opacity-0" enterTo="opacity-100"
          leave="ease-in duration-200" leaveFrom="opacity-100" leaveTo="opacity-0"
        >
          <div className="fixed inset-0 bg-black/75 backdrop-blur-sm" />
        </Transition.Child>

        <div className="fixed inset-0 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <Transition.Child
              as={Fragment}
              enter="ease-out duration-300" enterFrom="opacity-0 scale-95" enterTo="opacity-100 scale-100"
              leave="ease-in duration-200" leaveFrom="opacity-100 scale-100" leaveTo="opacity-0 scale-95"
            >
              <Dialog.Panel className="w-full max-w-md transform overflow-hidden rounded-2xl bg-[#151932] border border-[#1f2544] p-6 shadow-xl transition-all">
                <div className="flex items-center justify-between mb-6">
                  <Dialog.Title className="text-xl font-bold text-white">Add to Watchlist</Dialog.Title>
                  <button onClick={onClose} className="text-gray-400 hover:text-gray-200 transition-colors">
                    <XMarkIcon className="w-6 h-6" />
                  </button>
                </div>

                {error && (
                  <div className="bg-[#ef4444]/10 border border-[#ef4444]/50 rounded-lg p-3 mb-4">
                    <p className="text-[#ef4444] text-sm">{error}</p>
                  </div>
                )}

                <form onSubmit={handleSubmit} className="space-y-4">
                  <div>
                    <label className={labelClass}>Name <span className="text-[#ef4444]">*</span></label>
                    <input
                      name="name"
                      value={form.name}
                      onChange={handleChange}
                      required
                      placeholder="e.g. ASML Holding"
                      className={inputClass}
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className={labelClass}>Ticker (optional)</label>
                      <input
                        name="symbol"
                        value={form.symbol}
                        onChange={handleChange}
                        placeholder="e.g. ASML"
                        className={inputClass}
                      />
                    </div>
                    <div>
                      <label className={labelClass}>Country (optional)</label>
                      <input
                        name="country"
                        value={form.country}
                        onChange={handleChange}
                        placeholder="e.g. NLD"
                        maxLength={3}
                        className={inputClass}
                      />
                    </div>
                  </div>

                  <div>
                    <label className={labelClass}>Sector (optional)</label>
                    <input
                      name="sector"
                      value={form.sector}
                      onChange={handleChange}
                      placeholder="e.g. Semiconductors"
                      className={inputClass}
                    />
                  </div>

                  <div>
                    <label className={labelClass}>Priority</label>
                    <select
                      name="priority"
                      value={form.priority}
                      onChange={handleChange}
                      className={inputClass}
                    >
                      <option value="high">High</option>
                      <option value="normal">Normal</option>
                      <option value="low">Low</option>
                    </select>
                  </div>

                  <div>
                    <label className={labelClass}>Reason (optional)</label>
                    <textarea
                      name="reason"
                      value={form.reason}
                      onChange={handleChange}
                      placeholder="Why are you watching this?"
                      rows={3}
                      className={`${inputClass} resize-none`}
                    />
                  </div>

                  <div className="flex gap-3 pt-2">
                    <Button type="button" variant="secondary" onClick={onClose} className="flex-1">
                      Cancel
                    </Button>
                    <Button type="submit" variant="primary" disabled={loading} className="flex-1">
                      {loading ? <LoadingSpinner size="sm" /> : <PlusIcon className="w-4 h-4" />}
                      Add Item
                    </Button>
                  </div>
                </form>
              </Dialog.Panel>
            </Transition.Child>
          </div>
        </div>
      </Dialog>
    </Transition>
  );
}

interface WatchlistCardProps {
  item: WatchlistItem;
  onRemove: (id: string) => void;
  removing: boolean;
}

function WatchlistCard({ item, onRemove, removing }: WatchlistCardProps) {
  return (
    <div className="bg-[#151932] border border-[#1f2544] rounded-xl p-5 hover:border-[#252b4a] transition-colors">
      <div className="flex items-start justify-between gap-3">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 flex-wrap mb-1">
            <h3 className="text-white font-semibold text-base truncate">{item.name}</h3>
            {item.symbol && (
              <span className="px-2 py-0.5 bg-[#22d3ee]/10 text-[#22d3ee] border border-[#22d3ee]/30 rounded text-xs font-mono font-bold shrink-0">
                {item.symbol}
              </span>
            )}
          </div>

          <div className="flex items-center gap-2 flex-wrap mb-3">
            <PriorityBadge priority={item.priority} />
            <SourceBadge source={item.source} />
          </div>

          {(item.sector || item.country) && (
            <div className="flex gap-4 mb-3">
              {item.sector && (
                <div>
                  <p className="text-xs text-gray-500 mb-0.5">Sector</p>
                  <p className="text-sm text-gray-300">{item.sector}</p>
                </div>
              )}
              {item.country && (
                <div>
                  <p className="text-xs text-gray-500 mb-0.5">Country</p>
                  <p className="text-sm text-gray-300">{item.country}</p>
                </div>
              )}
            </div>
          )}

          {item.reason && (
            <p className="text-sm text-gray-400 leading-relaxed mb-3 line-clamp-3">{item.reason}</p>
          )}

          <p className="text-xs text-gray-600">
            Added {format(new Date(item.created_at), 'MMM d, yyyy')}
          </p>
        </div>

        <button
          onClick={() => onRemove(item.id)}
          disabled={removing}
          title="Remove from watchlist"
          className="shrink-0 p-2 rounded-lg text-gray-500 hover:text-[#ef4444] hover:bg-[#ef4444]/10 transition-all duration-200 disabled:opacity-50"
        >
          <TrashIcon className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}

export function Watchlist() {
  const [items, setItems] = useState<WatchlistItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [removingId, setRemovingId] = useState<string | null>(null);

  useEffect(() => {
    fetchWatchlist();
  }, []);

  const fetchWatchlist = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await watchlistService.getWatchlist();
      setItems(data);
    } catch {
      setError('Failed to load watchlist');
    } finally {
      setLoading(false);
    }
  };

  const handleRemove = async (id: string) => {
    setRemovingId(id);
    try {
      await watchlistService.removeItem(id);
      setItems(prev => prev.filter(item => item.id !== id));
    } catch {
      setError('Failed to remove item');
    } finally {
      setRemovingId(null);
    }
  };

  // Group by priority
  const grouped = PRIORITY_ORDER.map(priority => ({
    priority,
    items: items.filter(item => (item.priority ?? 'normal') === priority),
  })).filter(group => group.items.length > 0);

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
          <h1 className="text-3xl font-bold text-white mb-2">Watchlist</h1>
          <p className="text-gray-400">
            {items.length} {items.length === 1 ? 'item' : 'items'} under watch
          </p>
        </div>
        <Button variant="primary" onClick={() => setIsAddModalOpen(true)}>
          <PlusIcon className="w-5 h-5" />
          Add Item
        </Button>
      </div>

      {error && (
        <div className="bg-[#ef4444]/10 border border-[#ef4444]/50 rounded-lg p-4 mb-6">
          <p className="text-[#ef4444]">{error}</p>
        </div>
      )}

      {items.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16">
          <div className="bg-[#151932] border border-[#1f2544] rounded-full p-6 mb-4">
            <EyeIcon className="w-12 h-12 text-gray-400" />
          </div>
          <h3 className="text-xl font-semibold text-white mb-2">Your watchlist is empty</h3>
          <p className="text-gray-400 mb-6 text-center max-w-sm">
            Track companies and ETFs you're interested in. AI agents also add candidates here during recommendations.
          </p>
          <Button variant="primary" onClick={() => setIsAddModalOpen(true)}>
            <PlusIcon className="w-5 h-5" />
            Add Item
          </Button>
        </div>
      ) : (
        <div className="space-y-8">
          {grouped.map(({ priority, items: groupItems }) => {
            const cfg = PRIORITY_CONFIG[priority as keyof typeof PRIORITY_CONFIG];
            return (
              <div key={priority}>
                <div className="flex items-center gap-2 mb-4">
                  <span className={`w-2 h-2 rounded-full ${cfg.dot}`} />
                  <h2 className={`text-sm font-semibold uppercase tracking-wider ${cfg.color}`}>
                    {cfg.label} priority
                  </h2>
                  <span className="text-xs text-gray-600">({groupItems.length})</span>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
                  {groupItems.map(item => (
                    <WatchlistCard
                      key={item.id}
                      item={item}
                      onRemove={handleRemove}
                      removing={removingId === item.id}
                    />
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      )}

      <AddItemModal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
        onSuccess={fetchWatchlist}
      />
    </div>
  );
}
