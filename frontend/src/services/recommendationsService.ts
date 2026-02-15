import { storage } from '@utils/storage';
import type { AgentStreamEvent } from '@types/index';

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
  streamRecommendation(onEvent: (event: AgentStreamEvent) => void): () => void {
    const token = storage.getAccessToken();
    const abortController = new AbortController();

    const fetchStream = async () => {
      try {
        const response = await fetch('/api/investment/recommendations/generate', {
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
};
