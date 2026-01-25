import { useState, useRef, useEffect } from 'react';
import ReactMarkdown from 'react-markdown';
import { SparklesIcon, WrenchScrewdriverIcon, CheckCircleIcon, ChevronDownIcon, ChevronRightIcon, MagnifyingGlassIcon } from '@heroicons/react/24/outline';
import { Card } from '@components/common/Card';
import { Button } from '@components/common/Button';
import { recommendationsService } from '@services/recommendationsService';
import type { AgentStreamEvent, ToolCallEvent, StepStartEvent, StepCompleteEvent } from '@types/index';

interface ToolCall {
  id: number;
  tool_name: string;
  query: string | null;
}

interface WorkflowStep {
  step: number;
  name: string;
  status: 'pending' | 'in_progress' | 'completed';
  summary?: string;
  toolCalls: ToolCall[];
}

const WORKFLOW_STEPS: Pick<WorkflowStep, 'step' | 'name'>[] = [
  { step: 1, name: 'Market Discovery' },
  { step: 2, name: 'Building Candidate List' },
  { step: 3, name: 'Ethical Screening & Portfolio Fit' },
  { step: 4, name: 'Deep Dive Research' },
  { step: 5, name: 'Generating Recommendations' },
];

function parseToolInput(arguments_: string): string | null {
  try {
    const parsed = JSON.parse(arguments_);
    return parsed.input || parsed.query || null;
  } catch {
    return null;
  }
}

export function Recommendations() {
  const [recommendation, setRecommendation] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [workflowSteps, setWorkflowSteps] = useState<WorkflowStep[]>([]);
  const [activityExpanded, setActivityExpanded] = useState(true);
  const [expandedSteps, setExpandedSteps] = useState<Set<number>>(new Set());
  const toolCallIdRef = useRef(0);
  const currentStepRef = useRef<number | null>(null);
  const abortRef = useRef<(() => void) | null>(null);

  useEffect(() => {
    if (recommendation) {
      setActivityExpanded(false);
    }
  }, [recommendation]);

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
    setLoading(true);
    setError(null);
    setRecommendation(null);
    setWorkflowSteps(WORKFLOW_STEPS.map(s => ({ ...s, status: 'pending', toolCalls: [] })));
    setExpandedSteps(new Set());
    setActivityExpanded(true);
    toolCallIdRef.current = 0;
    currentStepRef.current = null;

    abortRef.current = recommendationsService.streamRecommendation((event: AgentStreamEvent) => {
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
        setWorkflowSteps(prev => prev.map(s =>
          s.step === stepEvent.step
            ? { ...s, status: 'completed', summary: stepEvent.summary }
            : s
        ));
      }

      if (event.type === 'tool_call') {
        const toolEvent = event as ToolCallEvent;
        // Capture current step NOW, before React batches the state update
        const stepForThisToolCall = currentStepRef.current;
        const toolCall: ToolCall = {
          id: toolCallIdRef.current++,
          tool_name: toolEvent.tool_name,
          query: parseToolInput(toolEvent.arguments),
        };
        // Add tool call to the captured step
        if (stepForThisToolCall !== null) {
          setWorkflowSteps(prev => prev.map(s =>
            s.step === stepForThisToolCall
              ? { ...s, toolCalls: [...s.toolCalls, toolCall] }
              : s
          ));
        }
      }

      if (event.type === 'final_output') {
        setRecommendation(event.recommendation);
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

      {/* Error Message */}
      {error && (
        <div className="bg-[#ef4444]/10 border border-[#ef4444]/50 rounded-lg p-4">
          <p className="text-[#ef4444]">{error}</p>
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
              Our AI will analyze your current portfolio and market conditions through a 5-step
              research workflow to provide personalized investment suggestions.
            </p>
          </div>
          <div className="flex gap-3 justify-center">
            <Button
              variant="primary"
              onClick={handleGenerateRecommendation}
              loading={loading}
              disabled={loading}
            >
              <SparklesIcon className="w-5 h-5" />
              {loading ? 'Generating...' : 'Ask for Recommendation'}
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
                  <h2 className="text-xl font-bold text-white">Research Workflow</h2>
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
                  const hasDetails = step.toolCalls.length > 0 || step.summary;

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
                                ({step.toolCalls.length} search{step.toolCalls.length !== 1 ? 'es' : ''})
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
                        <div className="px-3 pb-3 pt-0 ml-8 space-y-3">
                          {/* Tool calls / Web searches */}
                          {step.toolCalls.length > 0 && (
                            <div className="space-y-1">
                              {step.toolCalls.map((tc) => (
                                <div key={tc.id} className="flex items-center gap-2 text-sm">
                                  <MagnifyingGlassIcon className="w-4 h-4 text-[#22d3ee] flex-shrink-0" />
                                  <span className="text-gray-300">
                                    <span className="text-[#22d3ee]">{tc.tool_name}</span>
                                    {tc.query && <span className="text-gray-400 italic ml-2">"{tc.query}"</span>}
                                  </span>
                                </div>
                              ))}
                            </div>
                          )}

                          {/* Step summary/result */}
                          {step.summary && step.status === 'completed' && (
                            <div className="bg-[#0a0e27] rounded p-3 border border-[#1f2544]">
                              <div className="text-xs text-gray-500 mb-1 font-medium">Result</div>
                              <div className="text-sm text-gray-300 whitespace-pre-wrap max-h-48 overflow-y-auto">
                                {step.summary}
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
                    Starting research workflow...
                  </div>
                )}
              </div>
            )}
          </div>
        </Card>
      )}

      {/* Recommendation Result Card */}
      {recommendation && (
        <Card>
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-[#10b981]/10 flex items-center justify-center flex-shrink-0">
                <SparklesIcon className="w-6 h-6 text-[#10b981]" />
              </div>
              <h2 className="text-xl font-bold text-white">Your Personalized Recommendation</h2>
            </div>
            <div className="bg-[#0a0e27] rounded-lg p-6 border border-[#1f2544] prose prose-invert prose-sm max-w-none prose-headings:text-white prose-headings:font-semibold prose-p:text-gray-300 prose-strong:text-white prose-ul:text-gray-300 prose-ol:text-gray-300 prose-li:marker:text-[#22d3ee] prose-a:text-[#22d3ee] prose-code:text-[#a78bfa] prose-code:bg-[#1f2544] prose-code:px-1 prose-code:py-0.5 prose-code:rounded">
              <ReactMarkdown>{recommendation}</ReactMarkdown>
            </div>
          </div>
        </Card>
      )}
    </div>
  );
}
