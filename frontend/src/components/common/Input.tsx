import { InputHTMLAttributes, forwardRef } from 'react';

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helperText?: string;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, helperText, className = '', ...props }, ref) => {
    const baseClasses =
      'w-full px-4 py-2 bg-[#0a0e27] border rounded-lg text-gray-200 placeholder-gray-500 transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-[#151932] disabled:opacity-50 disabled:cursor-not-allowed';

    const stateClasses = error
      ? 'border-[#ef4444] focus:border-[#ef4444] focus:ring-[#ef4444]'
      : 'border-[#1f2544] focus:border-[#22d3ee] focus:ring-[#22d3ee]';

    return (
      <div className="w-full">
        {label && (
          <label className="block text-sm font-medium text-gray-300 mb-2">
            {label}
            {props.required && <span className="text-[#ef4444] ml-1">*</span>}
          </label>
        )}
        <input ref={ref} className={`${baseClasses} ${stateClasses} ${className}`} {...props} />
        {error && <p className="mt-1.5 text-sm text-[#ef4444]">{error}</p>}
        {helperText && !error && <p className="mt-1.5 text-sm text-gray-400">{helperText}</p>}
      </div>
    );
  }
);

Input.displayName = 'Input';
