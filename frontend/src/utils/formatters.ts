import { format, formatDistanceToNow, parseISO } from 'date-fns';

/**
 * Format a number as currency
 */
export function formatCurrency(value: number, currency = 'USD'): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);
}

/**
 * Format a number as percentage
 */
export function formatPercentage(value: number | string | null | undefined, decimals = 2): string {
  const numericValue = typeof value === 'string' ? Number(value) : value;
  if (numericValue === null || numericValue === undefined || Number.isNaN(numericValue)) {
    return '—';
  }
  return `${numericValue >= 0 ? '+' : ''}${numericValue.toFixed(decimals)}%`;
}

/**
 * Format a large number with K, M, B suffixes
 */
export function formatCompactNumber(value: number): string {
  const formatter = new Intl.NumberFormat('en-US', {
    notation: 'compact',
    compactDisplay: 'short',
    maximumFractionDigits: 1,
  });

  return formatter.format(value);
}

/**
 * Format a date string
 */
export function formatDate(dateString: string, formatString = 'MMM d, yyyy'): string {
  try {
    const date = parseISO(dateString);
    return format(date, formatString);
  } catch {
    return dateString;
  }
}

/**
 * Format a date as relative time (e.g., "2 hours ago")
 */
export function formatRelativeTime(dateString: string): string {
  try {
    const date = parseISO(dateString);
    return formatDistanceToNow(date, { addSuffix: true });
  } catch {
    return dateString;
  }
}

/**
 * Get color class for gain/loss value
 */
export function getGainLossColor(value: number | null): string {
  if (value === null || value === 0) return 'text-gray-400';
  return value > 0 ? 'text-success' : 'text-danger';
}

/**
 * Get performance status badge color
 */
export function getPerformanceColor(status: string): string {
  switch (status) {
    case 'profitable':
      return 'bg-success/20 text-success';
    case 'losing':
      return 'bg-danger/20 text-danger';
    case 'neutral':
      return 'bg-gray-500/20 text-gray-400';
    default:
      return 'bg-gray-500/20 text-gray-400';
  }
}

/**
 * Format asset type for display
 */
export function formatAssetType(assetType: string): string {
  return assetType.toUpperCase();
}

/**
 * Format risk tolerance for display
 */
export function formatRiskTolerance(risk: string): string {
  return risk.charAt(0).toUpperCase() + risk.slice(1);
}
