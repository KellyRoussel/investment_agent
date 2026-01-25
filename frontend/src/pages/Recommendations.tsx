import { useState } from 'react';
import ReactMarkdown from 'react-markdown';
import { SparklesIcon } from '@heroicons/react/24/outline';
import { Card } from '@components/common/Card';
import { Button } from '@components/common/Button';
import { recommendationsService } from '@services/recommendationsService';

export function Recommendations() {
  const [recommendation, setRecommendation] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleGenerateRecommendation = async () => {
    setLoading(true);
    setError(null);
    setRecommendation(null);

    try {
      const response = await recommendationsService.generateRecommendation();
      setRecommendation(response.recommendation);
    } catch (err: any) {
      console.error('Failed to generate recommendation:', err);
      setError(err.response?.data?.detail || 'Failed to generate recommendation. Please try again.');
    } finally {
      setLoading(false);
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
          <Button
            variant="primary"
            onClick={handleGenerateRecommendation}
            loading={loading}
            disabled={loading}
            className="mx-auto"
          >
            <SparklesIcon className="w-5 h-5" />
            {loading ? 'Generating...' : 'Ask for Recommendation'}
          </Button>
        </div>
      </Card>

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
