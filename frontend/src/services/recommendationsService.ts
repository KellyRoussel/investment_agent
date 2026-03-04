import { storage } from '@utils/storage';
import type { AgentStreamEvent, InvestmentReport } from '@types/index';
import { api } from './api';

/**
 * Recommendations service for AI-powered investment recommendations with SSE streaming
 */
export const recommendationsService = {
  /**
   * Generate AI-powered investment recommendations with streaming events.
   * Uses Server-Sent Events (SSE) to receive real-time updates.
   *
   * @param onEvent - Callback function called for each streaming event
   * @returns A function to abort the stream
   */
  async fetchModels(): Promise<{ models: string[]; default: string }> {
    const response = await api.get<{ models: string[]; default: string }>('/investment/models');
    return response.data;
  },

  streamRecommendation(budgetEur: number, model: string | null, onEvent: (event: AgentStreamEvent) => void): () => void {
    const token = storage.getAccessToken();
    const abortController = new AbortController();

    const fetchStream = async () => {
      try {
        const modelParam = model ? `&model=${encodeURIComponent(model)}` : '';
        const response = await fetch(`/api/investment/recommendations/generate/v2?budget_eur=${budgetEur}${modelParam}`, {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Accept': 'text/event-stream',
          },
          signal: abortController.signal,
        });

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        const reader = response.body?.getReader();
        if (!reader) {
          throw new Error('No response body');
        }

        const decoder = new TextDecoder();
        let buffer = '';

        while (true) {
          const { done, value } = await reader.read();
          if (done) break;

          buffer += decoder.decode(value, { stream: true });
          const lines = buffer.split('\n');

          // Keep the last incomplete line in the buffer
          buffer = lines.pop() || '';

          for (const line of lines) {
            if (line.startsWith('data: ')) {
              try {
                const data = JSON.parse(line.slice(6));
                onEvent(data as AgentStreamEvent);
              } catch (e) {
                console.error('Failed to parse SSE data:', line);
              }
            }
          }

          // Yield to the browser's macrotask queue so React's MessageChannel
          // scheduler can flush pending state updates before the next chunk.
          // Without this, rapid microtask-resolved reads batch all setState
          // calls into a single render at the end of the stream.
          await new Promise<void>(resolve => setTimeout(resolve, 0));
        }
      } catch (error: any) {
        if (error.name !== 'AbortError') {
          onEvent({ type: 'error', message: error.message || 'Stream failed' });
        }
      }
    };

    fetchStream();

    return () => abortController.abort();
  },

  async fetchHistory(): Promise<InvestmentReport[]> {
    const response = await api.get<InvestmentReport[]>('/investment/recommendations/history');
    return response.data;
  },
};
