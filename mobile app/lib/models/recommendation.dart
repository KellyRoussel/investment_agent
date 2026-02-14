sealed class AgentStreamEvent {
  factory AgentStreamEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'step_start':
        return StepStartEvent.fromJson(json);
      case 'step_complete':
        return StepCompleteEvent.fromJson(json);
      case 'tool_call':
        return ToolCallEvent.fromJson(json);
      case 'tool_output':
        return ToolOutputEvent.fromJson(json);
      case 'message':
        return MessageEvent.fromJson(json);
      case 'final_output':
        return FinalOutputEvent.fromJson(json);
      case 'error':
        return ErrorEvent.fromJson(json);
      default:
        return MessageEvent(content: 'Unknown event: $type');
    }
  }
}

class StepStartEvent implements AgentStreamEvent {
  final int step;
  final String name;

  StepStartEvent({required this.step, required this.name});

  factory StepStartEvent.fromJson(Map<String, dynamic> json) {
    return StepStartEvent(
      step: json['step'] as int,
      name: json['name'] as String,
    );
  }
}

class StepCompleteEvent implements AgentStreamEvent {
  final int step;
  final String summary;

  StepCompleteEvent({required this.step, required this.summary});

  factory StepCompleteEvent.fromJson(Map<String, dynamic> json) {
    return StepCompleteEvent(
      step: json['step'] as int,
      summary: json['summary'] as String,
    );
  }
}

class ToolCallEvent implements AgentStreamEvent {
  final String toolName;
  final String arguments;

  ToolCallEvent({required this.toolName, required this.arguments});

  factory ToolCallEvent.fromJson(Map<String, dynamic> json) {
    return ToolCallEvent(
      toolName: json['tool_name'] as String,
      arguments: json['arguments'] as String? ?? '',
    );
  }
}

class ToolOutputEvent implements AgentStreamEvent {
  final String output;

  ToolOutputEvent({required this.output});

  factory ToolOutputEvent.fromJson(Map<String, dynamic> json) {
    return ToolOutputEvent(output: json['output'] as String);
  }
}

class MessageEvent implements AgentStreamEvent {
  final String content;

  MessageEvent({required this.content});

  factory MessageEvent.fromJson(Map<String, dynamic> json) {
    return MessageEvent(content: json['content'] as String);
  }
}

class FinalOutputEvent implements AgentStreamEvent {
  final String recommendation;

  FinalOutputEvent({required this.recommendation});

  factory FinalOutputEvent.fromJson(Map<String, dynamic> json) {
    return FinalOutputEvent(recommendation: json['recommendation'] as String);
  }
}

class ErrorEvent implements AgentStreamEvent {
  final String message;

  ErrorEvent({required this.message});

  factory ErrorEvent.fromJson(Map<String, dynamic> json) {
    return ErrorEvent(message: json['message'] as String);
  }
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
