import { useState, useRef, useEffect } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { SparklesIcon, WrenchScrewdriverIcon, CheckCircleIcon, ChevronDownIcon, ChevronRightIcon, MagnifyingGlassIcon, CpuChipIcon, PlusCircleIcon, ExclamationCircleIcon } from '@heroicons/react/24/outline';
import { Card } from '@components/common/Card';
import { Button } from '@components/common/Button';
import { AddInvestmentModal } from '@components/investment/AddInvestmentModal';
import { recommendationsService } from '@services/recommendationsService';
import type { AgentStreamEvent, StepStartEvent, StepCompleteEvent, ToolCallEvent, FinalReportEvent, InvestmentSuggestion, InvestmentInitialValues, InvestmentSuggestionsEvent, WorkflowCompleteEvent } from '@types/index';

interface ToolCall {
  id: number;
  tool_name: string;
  query: string | null;
}

interface WorkflowStep {
  step: number;
  name: string;
  status: 'pending' | 'in_progress' | 'completed';
  toolCalls: ToolCall[];
  result?: string;
}

const WORKFLOW_STEPS: Pick<WorkflowStep, 'step' | 'name'>[] = [
  { step: 1, name: 'Portfolio Review' },
  { step: 2, name: 'Macro & Sector Scan' },
  { step: 3, name: 'Opportunity Research' },
  { step: 4, name: 'Decision & Thesis' },
];

export function Recommendations() {
  const [budget, setBudget] = useState<string>('');
  const [recommendation, setRecommendation] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [workflowSteps, setWorkflowSteps] = useState<WorkflowStep[]>([]);
  const [activityExpanded, setActivityExpanded] = useState(true);
  const [expandedSteps, setExpandedSteps] = useState<Set<number>>(new Set());
  const [suggestions, setSuggestions] = useState<InvestmentSuggestion[]>([]);
  const [workflowCost, setWorkflowCost] = useState<Pick<WorkflowCompleteEvent, 'tokens_input' | 'tokens_cached' | 'tokens_output' | 'cost_usd' | 'model'> | null>(null);
  const [addModalOpen, setAddModalOpen] = useState(false);
  const [addModalInitialValues, setAddModalInitialValues] = useState<InvestmentInitialValues | undefined>(undefined);
  const [availableModels, setAvailableModels] = useState<string[]>([]);
  const [selectedModel, setSelectedModel] = useState<string>('gpt-5-mini');
  const toolCallIdRef = useRef(0);
  const currentStepRef = useRef<number | null>(null);
  const abortRef = useRef<(() => void) | null>(null);

  useEffect(() => {
    recommendationsService.fetchModels().then(data => {
      setAvailableModels(data.models);
    }).catch(() => {/* non-blocking */});
  }, []);

  const budgetValue = parseFloat(budget);
  const budgetValid = !isNaN(budgetValue) && budgetValue > 0;

  useEffect(() => {
    if (recommendation && !loading) {
      setActivityExpanded(false);
    }
  }, [recommendation, loading]);

  const toggleStepExpanded = (step: number) => {
    setExpandedSteps(prev => {
      const next = new Set(prev);
      if (next.has(step)) {
        next.delete(step);
      } else {
        next.add(step);
      }
      return next;
    });
  };

  const handleGenerateRecommendation = () => {
    if (!budgetValid) return;

    setLoading(true);
    setError(null);
    setRecommendation(null);
    setSuggestions([]);
    setWorkflowCost(null);
    setWorkflowSteps(WORKFLOW_STEPS.map(s => ({ ...s, status: 'pending', toolCalls: [] })));
    setExpandedSteps(new Set());
    setActivityExpanded(true);
    toolCallIdRef.current = 0;
    currentStepRef.current = null;

    abortRef.current = recommendationsService.streamRecommendation(budgetValue, selectedModel, (event: AgentStreamEvent) => {
      if (event.type === 'step_start') {
        const stepEvent = event as StepStartEvent;
        currentStepRef.current = stepEvent.step;
        setWorkflowSteps(prev => prev.map(s =>
          s.step === stepEvent.step
            ? { ...s, status: 'in_progress' }
            : s
        ));
      }

      if (event.type === 'step_complete') {
        const stepEvent = event as StepCompleteEvent;
        setWorkflowSteps(prev => {
          const updated = prev.map(s =>
            s.step === stepEvent.step
              ? { ...s, status: 'completed' as const, result: stepEvent.result }
              : s
          );
          // When step 3 completes, mark step 4 as in_progress
          if (stepEvent.step === 3) {
            return updated.map(s => s.step === 4 ? { ...s, status: 'in_progress' as const } : s);
          }
          return updated;
        });
      }

      if (event.type === 'tool_call') {
        const toolEvent = event as ToolCallEvent;
        const stepForThisToolCall = currentStepRef.current;
        const firstInput = Object.values(toolEvent.inputs)[0] ?? null;
        const toolCall: ToolCall = {
          id: toolCallIdRef.current++,
          tool_name: toolEvent.tool,
          query: firstInput,
        };
        if (stepForThisToolCall !== null) {
          setWorkflowSteps(prev => prev.map(s =>
            s.step === stepForThisToolCall
              ? { ...s, toolCalls: [...s.toolCalls, toolCall] }
              : s
          ));
        }
      }

      if (event.type === 'final_report') {
        const reportEvent = event as FinalReportEvent;
        setRecommendation(reportEvent.content);
      }

      if (event.type === 'investment_suggestions') {
        const suggestionsEvent = event as InvestmentSuggestionsEvent;
        setSuggestions(suggestionsEvent.suggestions);
      }

      if (event.type === 'workflow_complete') {
        const completionEvent = event as WorkflowCompleteEvent;
        setWorkflowSteps(prev => prev.map(s =>
          s.step === 4 ? { ...s, status: 'completed' as const } : s
        ));
        setWorkflowCost({
          tokens_input: completionEvent.tokens_input,
          tokens_cached: completionEvent.tokens_cached,
          tokens_output: completionEvent.tokens_output,
          cost_usd: completionEvent.cost_usd,
          model: completionEvent.model,
        });
        setLoading(false);
      } else if (event.type === 'error') {
        setError(event.message);
        setLoading(false);
      }
    });
  };

  const handleCancel = () => {
    if (abortRef.current) {
      abortRef.current();
      abortRef.current = null;
    }
    setLoading(false);
  };

  const getStepIcon = (status: WorkflowStep['status']) => {
    switch (status) {
      case 'completed':
        return <CheckCircleIcon className="w-5 h-5 text-[#10b981]" />;
      case 'in_progress':
        return (
          <div className="w-5 h-5 border-2 border-[#22d3ee] border-t-transparent rounded-full animate-spin" />
        );
      default:
        return <div className="w-5 h-5 rounded-full border-2 border-gray-600" />;
    }
  };

  const handleOpenSuggestion = (s: InvestmentSuggestion) => {
    setAddModalInitialValues({
      account_type: s.account_type,
      ticker_symbol: s.symbol,
      suggested_quantity: s.suggested_quantity,
      investment_thesis: s.investment_thesis,
      notes: s.notes,
      alert_threshold_pct: s.alert_threshold_pct,
    });
    setAddModalOpen(true);
  };

  const formatQuantity = (q: number) => parseFloat(q.toFixed(4)).toString();

  // Extract a human-readable message from raw Python/OpenAI exception strings
  const formatError = (raw: string): string => {
    const msgMatch = raw.match(/"message":\s*"([^"]+)"/);
    if (msgMatch) return msgMatch[1];
    const pyMatch = raw.match(/'message':\s*'([^']+)'/);
    if (pyMatch) return pyMatch[1];
    return raw.length > 300 ? raw.slice(0, 300) + '…' : raw;
  };

  const currentStepName = workflowSteps.find(s => s.status === 'in_progress')?.name;
  const completedSteps = workflowSteps.filter(s => s.status === 'completed').length;

  return (
    <div className="p-8 max-w-4xl mx-auto space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-white mb-2">AI Recommendations</h1>
        <p className="text-gray-400">
          Get personalized investment recommendations based on your portfolio and market trends
        </p>
      </div>

      {/* Pre-workflow error (network / auth failure before the stream started) */}
      {error && workflowSteps.length === 0 && (
        <div className="bg-[#ef4444]/10 border border-[#ef4444]/50 rounded-lg p-4 flex items-start gap-3">
          <ExclamationCircleIcon className="w-5 h-5 text-[#ef4444] flex-shrink-0 mt-0.5" />
          <p className="text-[#ef4444] text-sm">{formatError(error)}</p>
        </div>
      )}

      {/* Generate Button Card */}
      <Card>
        <div className="text-center space-y-6">
          <div className="w-16 h-16 rounded-full bg-gradient-to-br from-[#22d3ee]/20 to-[#a78bfa]/20 flex items-center justify-center mx-auto">
            <SparklesIcon className="w-8 h-8 text-[#22d3ee]" />
          </div>
          <div>
            <h2 className="text-xl font-bold text-white mb-2">Generate Investment Recommendation</h2>
            <p className="text-gray-400">
              Our AI will review your portfolio, scan macro trends, research opportunities, and
              deliver a personalized investment thesis — all in a structured 4-step workflow.
            </p>
          </div>

          {/* Budget Input */}
          <div className="flex items-center gap-3 justify-center">
            <label className="text-gray-400 text-sm whitespace-nowrap">Monthly budget</label>
            <div className="relative">
              <input
                type="number"
                min="1"
                step="any"
                value={budget}
                onChange={e => setBudget(e.target.value)}
                disabled={loading}
                placeholder="e.g. 100"
                className="w-32 bg-[#0a0e27] border border-[#1f2544] rounded-lg pl-3 pr-10 py-2 text-white text-sm focus:outline-none focus:border-[#22d3ee] disabled:opacity-50"
              />
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm pointer-events-none">
                EUR
              </span>
            </div>
          </div>

          {/* Model Selector */}
          {availableModels.length > 0 && (
            <div className="flex items-center gap-3 justify-center">
              <label className="text-gray-400 text-sm whitespace-nowrap">Model</label>
              <select
                value={selectedModel}
                onChange={e => setSelectedModel(e.target.value)}
                disabled={loading}
                className="bg-[#0a0e27] border border-[#1f2544] rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-[#22d3ee] disabled:opacity-50"
              >
                {availableModels.map(m => (
                  <option key={m} value={m}>{m}</option>
                ))}
              </select>
            </div>
          )}

          <div className="flex gap-3 justify-center">
            <Button
              variant="primary"
              onClick={handleGenerateRecommendation}
              loading={loading}
              disabled={loading || !budgetValid}
            >
              <SparklesIcon className="w-5 h-5" />
              {loading ? 'Analysing...' : 'Ask for Recommendation'}
            </Button>
            {loading && (
              <Button variant="secondary" onClick={handleCancel}>
                Cancel
              </Button>
            )}
          </div>
        </div>
      </Card>

      {/* Workflow Progress Card */}
      {(loading || workflowSteps.length > 0) && (
        <Card>
          <div>
            <button
              onClick={() => setActivityExpanded(!activityExpanded)}
              className="w-full flex items-center justify-between cursor-pointer"
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-[#a78bfa]/10 flex items-center justify-center flex-shrink-0">
                  <WrenchScrewdriverIcon className="w-6 h-6 text-[#a78bfa]" />
                </div>
                <div className="text-left">
                  <h2 className="text-xl font-bold text-white">Analysis Workflow</h2>
                  <p className="text-sm text-gray-400">
                    {completedSteps} of {WORKFLOW_STEPS.length} steps completed
                    {currentStepName && !activityExpanded && (
                      <span> · <span className="text-[#22d3ee]">{currentStepName}</span></span>
                    )}
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                {loading && (
                  <div className="flex items-center gap-2 text-[#22d3ee]">
                    <div className="w-2 h-2 bg-[#22d3ee] rounded-full animate-pulse" />
                    <span className="text-sm">Processing...</span>
                  </div>
                )}
                {activityExpanded ? (
                  <ChevronDownIcon className="w-5 h-5 text-gray-400" />
                ) : (
                  <ChevronRightIcon className="w-5 h-5 text-gray-400" />
                )}
              </div>
            </button>

            {activityExpanded && (
              <div className="mt-6 space-y-3">
                {workflowSteps.map((step) => {
                  const isExpanded = expandedSteps.has(step.step) || step.status === 'in_progress';
                  const hasDetails = step.toolCalls.length > 0 || !!step.result;

                  return (
                    <div
                      key={step.step}
                      className={`rounded-lg border transition-colors ${
                        step.status === 'in_progress'
                          ? 'bg-[#22d3ee]/5 border-[#22d3ee]/30'
                          : step.status === 'completed'
                          ? 'bg-[#10b981]/5 border-[#10b981]/20'
                          : 'bg-[#0a0e27] border-[#1f2544]'
                      }`}
                    >
                      {/* Step Header */}
                      <button
                        onClick={() => hasDetails && step.status === 'completed' && toggleStepExpanded(step.step)}
                        className={`w-full flex items-start gap-3 p-3 ${
                          hasDetails && step.status === 'completed' ? 'cursor-pointer' : 'cursor-default'
                        }`}
                      >
                        <div className="flex-shrink-0 mt-0.5">{getStepIcon(step.status)}</div>
                        <div className="flex-1 min-w-0 text-left">
                          <div className="flex items-center gap-2">
                            <span className="text-xs text-gray-500 font-mono">Step {step.step}</span>
                            <span className={`font-medium ${
                              step.status === 'in_progress'
                                ? 'text-[#22d3ee]'
                                : step.status === 'completed'
                                ? 'text-white'
                                : 'text-gray-400'
                            }`}>
                              {step.name}
                            </span>
                            {step.toolCalls.length > 0 && (
                              <span className="text-xs text-gray-500">
                                ({step.toolCalls.length} call{step.toolCalls.length !== 1 ? 's' : ''})
                              </span>
                            )}
                          </div>
                        </div>
                        {hasDetails && step.status === 'completed' && (
                          <div className="flex-shrink-0">
                            {isExpanded ? (
                              <ChevronDownIcon className="w-4 h-4 text-gray-500" />
                            ) : (
                              <ChevronRightIcon className="w-4 h-4 text-gray-500" />
                            )}
                          </div>
                        )}
                      </button>

                      {/* Step Details (expanded) */}
                      {isExpanded && hasDetails && (
                        <div className="px-3 pb-3 pt-0 ml-8 space-y-2">
                          {/* Tool calls */}
                          {step.toolCalls.length > 0 && (
                            <div className="space-y-1">
                              {step.toolCalls.map((tc) => (
                                <div key={tc.id} className="flex items-center gap-2 text-sm">
                                  {tc.tool_name === 'web_search' ? (
                                    <MagnifyingGlassIcon className="w-4 h-4 text-[#22d3ee] flex-shrink-0" />
                                  ) : (
                                    <CpuChipIcon className="w-4 h-4 text-[#a78bfa] flex-shrink-0" />
                                  )}
                                  <span className="text-gray-300">
                                    <span className={tc.tool_name === 'web_search' ? 'text-[#22d3ee]' : 'text-[#a78bfa]'}>
                                      {tc.tool_name}
                                    </span>
                                    {tc.query && (
                                      <span className="text-gray-400 italic ml-2">"{tc.query}"</span>
                                    )}
                                  </span>
                                </div>
                              ))}
                            </div>
                          )}

                          {/* Agent result report */}
                          {step.result && (
                            <div className={step.toolCalls.length > 0 ? 'border-t border-[#1f2544] pt-2' : ''}>
                              <p className="text-xs text-gray-500 mb-1.5">Agent report</p>
                              <div className="max-h-72 overflow-y-auto rounded-lg bg-[#070b1c] border border-[#1f2544] p-3 prose prose-invert prose-xs max-w-none prose-p:text-gray-300 prose-p:my-1 prose-headings:text-white prose-headings:font-semibold prose-strong:text-white prose-ul:text-gray-300 prose-ol:text-gray-300 prose-li:my-0.5 prose-li:marker:text-[#22d3ee] prose-table:w-full prose-th:text-white prose-th:font-semibold prose-th:bg-[#1f2544] prose-th:px-2 prose-th:py-1 prose-td:text-gray-300 prose-td:px-2 prose-td:py-1 prose-td:border-[#1f2544]">
                                <ReactMarkdown remarkPlugins={[remarkGfm]}>{step.result}</ReactMarkdown>
                              </div>
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  );
                })}

                {loading && workflowSteps.every(s => s.status === 'pending') && (
                  <div className="text-center py-4 text-gray-400">
                    <div className="animate-spin w-6 h-6 border-2 border-[#22d3ee] border-t-transparent rounded-full mx-auto mb-3" />
                    Starting analysis workflow...
                  </div>
                )}
              </div>
            )}

            {/* In-context error — shown inside the workflow card when the analysis fails */}
            {!loading && error && (
              <div className="mt-4 rounded-lg border border-[#ef4444]/30 bg-[#ef4444]/10 p-4 flex items-start gap-3">
                <ExclamationCircleIcon className="w-5 h-5 text-[#ef4444] flex-shrink-0 mt-0.5" />
                <div>
                  <p className="text-sm font-semibold text-[#ef4444] mb-1">Analysis failed</p>
                  <p className="text-xs text-[#ef4444]/80 leading-relaxed">{formatError(error)}</p>
                </div>
              </div>
            )}
          </div>
        </Card>
      )}

      {/* Workflow cost banner */}
      {workflowCost && (
        <div className="flex items-center gap-3 px-4 py-2.5 rounded-lg border border-[#1f2544] bg-[#151932] text-sm">
          <span className="text-gray-500">Workflow cost</span>
          <div className="flex items-center gap-2 ml-auto">
            <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-[#a78bfa]/10 text-[#a78bfa] border border-[#a78bfa]/30">
              {((workflowCost.tokens_input + workflowCost.tokens_output) / 1000).toFixed(1)}k tokens
            </span>
            {workflowCost.tokens_cached > 0 && (
              <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-[#f59e0b]/10 text-[#f59e0b] border border-[#f59e0b]/30">
                {(workflowCost.tokens_cached / 1000).toFixed(1)}k cached
              </span>
            )}
            <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-[#22d3ee]/10 text-[#22d3ee] border border-[#22d3ee]/30">
              {workflowCost.cost_usd < 0.01
                ? `$${workflowCost.cost_usd.toFixed(4)}`
                : `$${workflowCost.cost_usd.toFixed(3)}`}
            </span>
          </div>
        </div>
      )}

      {/* Recommendation Result Card */}
      <AddInvestmentModal
        isOpen={addModalOpen}
        onClose={() => setAddModalOpen(false)}
        onSuccess={() => setAddModalOpen(false)}
        initialValues={addModalInitialValues}
      />

      {recommendation && (
        <Card>
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-[#10b981]/10 flex items-center justify-center flex-shrink-0">
                <SparklesIcon className="w-6 h-6 text-[#10b981]" />
              </div>
              <div className="flex-1">
                <h2 className="text-xl font-bold text-white">Your Personalized Recommendation</h2>
              </div>
              {loading && (
                <div className="w-4 h-4 border-2 border-[#22d3ee] border-t-transparent rounded-full animate-spin flex-shrink-0" />
              )}
            </div>
            <div className="bg-[#0a0e27] rounded-lg p-6 border border-[#1f2544] prose prose-invert prose-sm max-w-none prose-headings:text-white prose-headings:font-semibold prose-p:text-gray-300 prose-strong:text-white prose-ul:text-gray-300 prose-ol:text-gray-300 prose-li:marker:text-[#22d3ee] prose-a:text-[#22d3ee] prose-code:text-[#a78bfa] prose-code:bg-[#1f2544] prose-code:px-1 prose-code:py-0.5 prose-code:rounded">
              <ReactMarkdown>{recommendation}</ReactMarkdown>
            </div>

            {suggestions.length > 0 && (
              <div className="pt-4 border-t border-[#1f2544]">
                <p className="text-sm text-gray-400 mb-3">Add suggested investment to your portfolio:</p>
                <div className="flex flex-wrap gap-3">
                  {suggestions.map((s) => (
                    <button
                      key={s.symbol}
                      onClick={() => handleOpenSuggestion(s)}
                      className="flex items-center gap-2.5 px-4 py-2.5 rounded-xl border border-[#22d3ee]/30 bg-[#22d3ee]/5 hover:bg-[#22d3ee]/10 hover:border-[#22d3ee]/50 transition-colors text-left"
                    >
                      <PlusCircleIcon className="w-5 h-5 text-[#22d3ee] flex-shrink-0" />
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-bold text-white">{s.symbol}</span>
                          <span className="px-2 py-0.5 rounded-full text-xs font-medium border bg-[#a78bfa]/10 text-[#a78bfa] border-[#a78bfa]/30">
                            {s.account_type}
                          </span>
                        </div>
                        <p className="text-xs text-gray-400 mt-0.5">
                          {s.name}
                          {s.allocation_eur != null && (
                            <span className="text-gray-500"> · {s.allocation_eur} EUR</span>
                          )}
                          {s.suggested_quantity != null && s.current_price != null && (
                            <span className="text-gray-500"> · ~{formatQuantity(s.suggested_quantity)} shares @ {s.current_price} {s.currency}</span>
                          )}
                        </p>
                      </div>
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>
        </Card>
      )}
    </div>
  );
}
