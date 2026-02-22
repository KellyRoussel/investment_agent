import { useState, useEffect } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { ChevronDownIcon, ChevronUpIcon } from '@heroicons/react/24/outline';
import { recommendationsService } from '@services/recommendationsService';
import type { InvestmentReport } from '@types/index';

function formatDate(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
}

function formatCost(cost: number | null): string {
  if (cost === null) return '—';
  if (cost < 0.01) return `$${cost.toFixed(5)}`;
  return `$${cost.toFixed(4)}`;
}

function formatTokens(input: number | null, output: number | null): string {
  if (input === null && output === null) return '—';
  const i = input?.toLocaleString() ?? '?';
  const o = output?.toLocaleString() ?? '?';
  return `${i} in / ${o} out`;
}

function StatusBadge({ status }: { status: InvestmentReport['status'] }) {
  const styles = {
    completed: 'bg-[#10b981]/15 text-[#10b981] border border-[#10b981]/30',
    in_progress: 'bg-[#22d3ee]/15 text-[#22d3ee] border border-[#22d3ee]/30',
    failed: 'bg-[#ef4444]/15 text-[#ef4444] border border-[#ef4444]/30',
  };
  const labels = { completed: 'Completed', in_progress: 'In Progress', failed: 'Failed' };
  return (
    <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${styles[status]}`}>
      {labels[status]}
    </span>
  );
}

function ReportCard({ report }: { report: InvestmentReport }) {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className="bg-[#151932] border border-[#1f2544] rounded-xl overflow-hidden transition-all duration-200">
      {/* Card header — always visible */}
      <button
        onClick={() => setExpanded((v) => !v)}
        className="w-full text-left px-6 py-4 flex items-center justify-between gap-4 hover:bg-[#1a2040] transition-colors duration-150"
      >
        <div className="flex flex-wrap items-center gap-4 min-w-0">
          {/* Date */}
          <span className="text-white font-semibold whitespace-nowrap">
            {formatDate(report.report_date)}
          </span>

          <StatusBadge status={report.status} />

          {/* Model */}
          {report.model_used && (
            <span className="text-xs text-[#a78bfa] font-mono bg-[#a78bfa]/10 border border-[#a78bfa]/20 px-2 py-0.5 rounded-full whitespace-nowrap">
              {report.model_used}
            </span>
          )}

          {/* Cost */}
          <span className="text-sm text-gray-300 whitespace-nowrap">
            <span className="text-gray-500 mr-1">Cost:</span>
            <span className="text-[#22d3ee] font-medium">{formatCost(report.cost_usd)}</span>
          </span>

          {/* Tokens */}
          <span className="hidden sm:inline text-sm text-gray-500 whitespace-nowrap">
            {formatTokens(report.tokens_input, report.tokens_output)}
          </span>
        </div>

        {/* Expand icon */}
        {report.final_recommendation ? (
          expanded ? (
            <ChevronUpIcon className="w-5 h-5 text-gray-400 flex-shrink-0" />
          ) : (
            <ChevronDownIcon className="w-5 h-5 text-gray-400 flex-shrink-0" />
          )
        ) : (
          <span className="text-xs text-gray-600 flex-shrink-0">No content</span>
        )}
      </button>

      {/* Expanded recommendation */}
      {expanded && report.final_recommendation && (
        <div className="px-6 pb-6 border-t border-[#1f2544] pt-4">
          <div className="bg-[#0a0e27] rounded-lg p-5 border border-[#1f2544] prose prose-invert prose-sm max-w-none prose-headings:text-white prose-headings:font-semibold prose-p:text-gray-300 prose-strong:text-white prose-ul:text-gray-300 prose-ol:text-gray-300 prose-li:marker:text-[#22d3ee] prose-a:text-[#22d3ee] prose-code:text-[#a78bfa] prose-code:bg-[#1f2544] prose-code:px-1 prose-code:py-0.5 prose-code:rounded">
            <ReactMarkdown remarkPlugins={[remarkGfm]}>
              {report.final_recommendation}
            </ReactMarkdown>
          </div>
        </div>
      )}
    </div>
  );
}

export function ReportHistory() {
  const [reports, setReports] = useState<InvestmentReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    recommendationsService
      .fetchHistory()
      .then(setReports)
      .catch((err) => setError(err?.response?.data?.detail ?? err.message ?? 'Failed to load reports'))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="p-6 max-w-4xl mx-auto">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white">Report History</h1>
        <p className="text-gray-400 mt-1">Your last 12 AI-generated investment reports</p>
      </div>

      {loading && (
        <div className="flex justify-center py-16">
          <div className="w-8 h-8 border-2 border-[#22d3ee] border-t-transparent rounded-full animate-spin" />
        </div>
      )}

      {!loading && error && (
        <div className="bg-[#ef4444]/10 border border-[#ef4444]/30 rounded-xl px-6 py-4 text-[#ef4444]">
          {error}
        </div>
      )}

      {!loading && !error && reports.length === 0 && (
        <div className="text-center py-20 text-gray-500">
          <p className="text-lg">No completed reports yet.</p>
          <p className="text-sm mt-1">Generate your first recommendation to see it here.</p>
        </div>
      )}

      {!loading && !error && reports.length > 0 && (
        <div className="space-y-3">
          {reports.map((report) => (
            <ReportCard key={report.id} report={report} />
          ))}
        </div>
      )}
    </div>
  );
}
