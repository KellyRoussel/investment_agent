import { useState, useRef, useEffect } from 'react';
import ReactMarkdown from 'react-markdown';
import { SparklesIcon, WrenchScrewdriverIcon, ArrowPathIcon, ChatBubbleLeftRightIcon, CheckCircleIcon, ChevronDownIcon, ChevronRightIcon } from '@heroicons/react/24/outline';
import { Card } from '@components/common/Card';
import { Button } from '@components/common/Button';
import { recommendationsService } from '@services/recommendationsService';
import type { AgentStreamEvent, ToolCallEvent, ToolOutputEvent } from '@types/index';

interface StreamingEvent {
  id: number;
  type: AgentStreamEvent['type'];
  data: AgentStreamEvent;
  timestamp: Date;
}

function parseToolInput(arguments_: string): string | null {
  try {
    const parsed = JSON.parse(arguments_);
    // Handle both regular tools (input) and web_search (query)
    return parsed.input || parsed.query || null;
  } catch {
    return null;
  }
}

function summarizeToolOutput(output: string): string {
  // Try to extract key information from the output
  const lines = output.split('\n').filter(line => line.trim());
  if (lines.length <= 3) {
    return output;
  }
  // Return first few meaningful lines
  return lines.slice(0, 3).join('\n') + `\n... (${lines.length - 3} more lines)`;
}

export function Recommendations() {
  const [recommendation, setRecommendation] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [events, setEvents] = useState<StreamingEvent[]>([]);
  const [currentAgent, setCurrentAgent] = useState<string | null>(null);
  const [activityExpanded, setActivityExpanded] = useState(true);
  const eventIdRef = useRef(0);
  const abortRef = useRef<(() => void) | null>(null);

  // Auto-collapse when recommendation arrives
  useEffect(() => {
    if (recommendation) {
      setActivityExpanded(false);
    }
  }, [recommendation]);

  const handleGenerateRecommendation = () => {
    setLoading(true);
    setError(null);
    setRecommendation(null);
    setEvents([]);
    setCurrentAgent('Orchestrator agent');
    setActivityExpanded(true);
    eventIdRef.current = 0;

    abortRef.current = recommendationsService.streamRecommendation((event: AgentStreamEvent) => {
      const streamingEvent: StreamingEvent = {
        id: eventIdRef.current++,
        type: event.type,
        data: event,
        timestamp: new Date(),
      };

      if (event.type === 'agent_change') {
        setCurrentAgent(event.agent_name);
      }

      if (event.type === 'final_output') {
        setRecommendation(event.recommendation);
        setLoading(false);
      } else if (event.type === 'error') {
        setError(event.message);
        setLoading(false);
      } else {
        setEvents((prev) => [...prev, streamingEvent]);
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

  const getEventIcon = (type: AgentStreamEvent['type']) => {
    switch (type) {
      case 'agent_change':
        return <ArrowPathIcon className="w-4 h-4 text-[#a78bfa]" />;
      case 'tool_call':
        return <WrenchScrewdriverIcon className="w-4 h-4 text-[#22d3ee]" />;
      case 'tool_output':
        return <CheckCircleIcon className="w-4 h-4 text-[#10b981]" />;
      case 'message':
        return <ChatBubbleLeftRightIcon className="w-4 h-4 text-[#f59e0b]" />;
      default:
        return <SparklesIcon className="w-4 h-4 text-gray-400" />;
    }
  };

  const renderEventContent = (event: StreamingEvent) => {
    switch (event.data.type) {
      case 'agent_change':
        return (
          <div className="text-[#a78bfa]">
            <span className="font-medium">Agent switched to:</span> {event.data.agent_name}
          </div>
        );
      case 'tool_call': {
        const toolEvent = event.data as ToolCallEvent;
        const inputText = parseToolInput(toolEvent.arguments);
        return (
          <div>
            <div className="text-[#22d3ee] font-medium">{toolEvent.tool_name}</div>
            {inputText && (
              <p className="mt-1 text-gray-300 text-sm italic">"{inputText}"</p>
            )}
          </div>
        );
      }
      case 'tool_output': {
        const outputEvent = event.data as ToolOutputEvent;
        const summary = summarizeToolOutput(outputEvent.output);
        return (
          <div>
            <div className="text-[#10b981] font-medium">Result received</div>
            <p className="mt-1 text-xs text-gray-400 whitespace-pre-wrap">{summary}</p>
          </div>
        );
      }
      case 'message':
        return (
          <div className="text-gray-300">
            <span className="font-medium text-[#f59e0b]">Message:</span> {event.data.content.slice(0, 200)}
            {event.data.content.length > 200 && '...'}
          </div>
        );
      default:
        return null;
    }
  };

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
              Our AI agent will analyze your current portfolio and market conditions to provide
              personalized investment suggestions.
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

      {/* Agent Activity Card - Collapsible */}
      {(loading || events.length > 0) && (
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
                  <h2 className="text-xl font-bold text-white">Agent Activity</h2>
                  <p className="text-sm text-gray-400">
                    {events.length} event{events.length !== 1 ? 's' : ''}
                    {currentAgent && !activityExpanded && (
                      <span> · Last: <span className="text-[#a78bfa]">{currentAgent}</span></span>
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
              <div className="mt-4 space-y-3 max-h-96 overflow-y-auto">
                {events.map((event) => (
                  <div
                    key={event.id}
                    className="flex gap-3 p-3 bg-[#0a0e27] rounded-lg border border-[#1f2544]"
                  >
                    <div className="flex-shrink-0 mt-1">{getEventIcon(event.type)}</div>
                    <div className="flex-1 min-w-0 text-sm">{renderEventContent(event)}</div>
                    <div className="flex-shrink-0 text-xs text-gray-500">
                      {event.timestamp.toLocaleTimeString()}
                    </div>
                  </div>
                ))}
                {loading && events.length === 0 && (
                  <div className="text-center py-8 text-gray-400">
                    <div className="animate-spin w-6 h-6 border-2 border-[#22d3ee] border-t-transparent rounded-full mx-auto mb-3" />
                    Starting AI agents...
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
