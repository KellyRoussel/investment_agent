double _toDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

sealed class AgentStreamEvent {
  factory AgentStreamEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'workflow_start':
        return WorkflowStartEvent.fromJson(json);
      case 'step_start':
        return StepStartEvent.fromJson(json);
      case 'step_complete':
        return StepCompleteEvent.fromJson(json);
      case 'tool_call':
        return ToolCallEvent.fromJson(json);
      case 'token':
        return TokenEvent.fromJson(json);
      case 'final_report':
        return FinalReportEvent.fromJson(json);
      case 'investment_suggestions':
        return InvestmentSuggestionsEvent.fromJson(json);
      case 'workflow_complete':
        return WorkflowCompleteEvent.fromJson(json);
      case 'error':
        return ErrorEvent.fromJson(json);
      default:
        return TokenEvent(content: '', agent: '');
    }
  }
}

class WorkflowStartEvent implements AgentStreamEvent {
  final String reportId;
  final String message;

  WorkflowStartEvent({required this.reportId, required this.message});

  factory WorkflowStartEvent.fromJson(Map<String, dynamic> json) {
    return WorkflowStartEvent(
      reportId: json['report_id'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

class StepStartEvent implements AgentStreamEvent {
  final int step;
  final String stepName;

  StepStartEvent({required this.step, required this.stepName});

  factory StepStartEvent.fromJson(Map<String, dynamic> json) {
    return StepStartEvent(
      step: json['step'] as int,
      stepName: json['step_name'] as String? ?? '',
    );
  }
}

class StepCompleteEvent implements AgentStreamEvent {
  final int step;
  final String? result;

  StepCompleteEvent({required this.step, this.result});

  factory StepCompleteEvent.fromJson(Map<String, dynamic> json) {
    return StepCompleteEvent(
      step: json['step'] as int,
      result: json['result'] as String?,
    );
  }
}

class ToolCallEvent implements AgentStreamEvent {
  final String tool;
  final Map<String, dynamic> inputs;

  ToolCallEvent({required this.tool, required this.inputs});

  factory ToolCallEvent.fromJson(Map<String, dynamic> json) {
    return ToolCallEvent(
      tool: json['tool'] as String? ?? '',
      inputs: (json['inputs'] as Map<String, dynamic>?) ?? {},
    );
  }
}

class TokenEvent implements AgentStreamEvent {
  final String content;
  final String agent;

  TokenEvent({required this.content, required this.agent});

  factory TokenEvent.fromJson(Map<String, dynamic> json) {
    return TokenEvent(
      content: json['content'] as String? ?? '',
      agent: json['agent'] as String? ?? '',
    );
  }
}

class FinalReportEvent implements AgentStreamEvent {
  final String content;

  FinalReportEvent({required this.content});

  factory FinalReportEvent.fromJson(Map<String, dynamic> json) {
    return FinalReportEvent(content: json['content'] as String? ?? '');
  }
}

class InvestmentSuggestion {
  final String symbol;
  final String? name;
  final String accountType;
  final double? allocationEur;
  final double? currentPrice;
  final String? currency;
  final double? suggestedQuantity;
  final String? investmentThesis;
  final String? notes;
  final double? alertThresholdPct;

  InvestmentSuggestion({
    required this.symbol,
    this.name,
    required this.accountType,
    this.allocationEur,
    this.currentPrice,
    this.currency,
    this.suggestedQuantity,
    this.investmentThesis,
    this.notes,
    this.alertThresholdPct,
  });

  factory InvestmentSuggestion.fromJson(Map<String, dynamic> json) {
    return InvestmentSuggestion(
      symbol: json['symbol'] as String,
      name: json['name'] as String?,
      accountType: json['account_type'] as String? ?? 'CTO',
      allocationEur: json['allocation_eur'] != null
          ? _toDouble(json['allocation_eur'])
          : null,
      currentPrice: json['current_price'] != null
          ? _toDouble(json['current_price'])
          : null,
      currency: json['currency'] as String?,
      suggestedQuantity: json['suggested_quantity'] != null
          ? _toDouble(json['suggested_quantity'])
          : null,
      investmentThesis: json['investment_thesis'] as String?,
      notes: json['notes'] as String?,
      alertThresholdPct: json['alert_threshold_pct'] != null
          ? _toDouble(json['alert_threshold_pct'])
          : null,
    );
  }
}

class InvestmentSuggestionsEvent implements AgentStreamEvent {
  final List<InvestmentSuggestion> suggestions;

  InvestmentSuggestionsEvent({required this.suggestions});

  factory InvestmentSuggestionsEvent.fromJson(Map<String, dynamic> json) {
    final list = json['suggestions'] as List<dynamic>? ?? [];
    return InvestmentSuggestionsEvent(
      suggestions: list
          .map((e) => InvestmentSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WorkflowCompleteEvent implements AgentStreamEvent {
  final String reportId;
  final int tokensInput;
  final int tokensCached;
  final int tokensOutput;
  final double costUsd;
  final String model;

  WorkflowCompleteEvent({
    required this.reportId,
    required this.tokensInput,
    required this.tokensCached,
    required this.tokensOutput,
    required this.costUsd,
    required this.model,
  });

  factory WorkflowCompleteEvent.fromJson(Map<String, dynamic> json) {
    return WorkflowCompleteEvent(
      reportId: json['report_id'] as String? ?? '',
      tokensInput: json['tokens_input'] as int? ?? 0,
      tokensCached: json['tokens_cached'] as int? ?? 0,
      tokensOutput: json['tokens_output'] as int? ?? 0,
      costUsd: (json['cost_usd'] as num?)?.toDouble() ?? 0.0,
      model: json['model'] as String? ?? '',
    );
  }
}

class ErrorEvent implements AgentStreamEvent {
  final String message;

  ErrorEvent({required this.message});

  factory ErrorEvent.fromJson(Map<String, dynamic> json) {
    return ErrorEvent(message: json['message'] as String? ?? 'Unknown error');
  }
}

class WorkflowCost {
  final int tokensInput;
  final int tokensCached;
  final int tokensOutput;
  final double costUsd;
  final String model;

  const WorkflowCost({
    required this.tokensInput,
    required this.tokensCached,
    required this.tokensOutput,
    required this.costUsd,
    required this.model,
  });

  int get totalTokens => tokensInput + tokensOutput;
  int get freshInputTokens => tokensInput - tokensCached;
  bool get hasCachedTokens => tokensCached > 0;
}

enum WorkflowStepStatus { pending, inProgress, completed }

class ToolCall {
  final int id;
  final String toolName;
  final String query;

  ToolCall({required this.id, required this.toolName, required this.query});
}

class WorkflowStep {
  final int step;
  final String name;
  WorkflowStepStatus status;
  String? summary;
  List<ToolCall> toolCalls;

  WorkflowStep({
    required this.step,
    required this.name,
    this.status = WorkflowStepStatus.pending,
    this.summary,
    List<ToolCall>? toolCalls,
  }) : toolCalls = toolCalls ?? [];
}
