import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/recommendation.dart';
import '../services/recommendations_service.dart';

class RecommendationsProvider extends ChangeNotifier {
  final RecommendationsService _service;

  List<WorkflowStep> _workflowSteps = [];
  String? _recommendation;
  bool _isLoading = false;
  String? _error;
  bool _activityExpanded = true;
  final Set<int> _expandedSteps = {};
  int _toolCallIdCounter = 0;
  int? _currentStep;
  CancelToken? _cancelToken;
  StreamSubscription? _subscription;
  WorkflowCost? _workflowCost;

  RecommendationsProvider(this._service);

  List<WorkflowStep> get workflowSteps => _workflowSteps;
  String? get recommendation => _recommendation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get activityExpanded => _activityExpanded;
  Set<int> get expandedSteps => _expandedSteps;
  int get completedSteps => _workflowSteps.where((s) => s.status == WorkflowStepStatus.completed).length;
  WorkflowCost? get workflowCost => _workflowCost;

  static const _stepNames = [
    'Market Discovery',
    'Building Candidate List',
    'Ethical Screening & Portfolio Fit',
    'Deep Dive Research',
    'Generating Recommendations',
  ];

  Future<void> generateRecommendation({required double budgetEur}) async {
    _isLoading = true;
    _error = null;
    _recommendation = null;
    _workflowCost = null;
    _toolCallIdCounter = 0;
    _currentStep = null;
    _expandedSteps.clear();
    _activityExpanded = true;

    _workflowSteps = List.generate(
      5,
      (i) => WorkflowStep(step: i + 1, name: _stepNames[i]),
    );
    notifyListeners();

    _cancelToken = CancelToken();

    try {
      final stream = _service.streamRecommendation(_cancelToken!, budgetEur: budgetEur);
      await for (final event in stream) {
        _handleEvent(event);
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        // User cancelled
      } else {
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleEvent(AgentStreamEvent event) {
    switch (event) {
      case StepStartEvent(:final step, :final name):
        final idx = step - 1;
        if (idx >= 0 && idx < _workflowSteps.length) {
          _workflowSteps[idx].status = WorkflowStepStatus.inProgress;
          _workflowSteps[idx] = WorkflowStep(
            step: step,
            name: name.isNotEmpty ? name : _workflowSteps[idx].name,
            status: WorkflowStepStatus.inProgress,
            toolCalls: _workflowSteps[idx].toolCalls,
          );
          _currentStep = idx;
          _expandedSteps.add(idx);
        }

      case StepCompleteEvent(:final step, :final summary):
        final idx = step - 1;
        if (idx >= 0 && idx < _workflowSteps.length) {
          _workflowSteps[idx] = WorkflowStep(
            step: step,
            name: _workflowSteps[idx].name,
            status: WorkflowStepStatus.completed,
            summary: summary,
            toolCalls: _workflowSteps[idx].toolCalls,
          );
        }

      case ToolCallEvent(:final toolName, :final arguments):
        if (_currentStep != null && _currentStep! < _workflowSteps.length) {
          _workflowSteps[_currentStep!].toolCalls.add(
            ToolCall(
              id: _toolCallIdCounter++,
              toolName: toolName,
              query: arguments,
            ),
          );
        }

      case FinalOutputEvent(:final recommendation):
        _recommendation = recommendation;
        _isLoading = false;

      case ErrorEvent(:final message):
        _error = message;
        _isLoading = false;

      case WorkflowCompleteEvent(:final tokensInput, :final tokensCached, :final tokensOutput, :final costUsd, :final model):
        _workflowCost = WorkflowCost(
          tokensInput: tokensInput,
          tokensCached: tokensCached,
          tokensOutput: tokensOutput,
          costUsd: costUsd,
          model: model,
        );

      case ToolOutputEvent():
      case MessageEvent():
        break;
    }
    notifyListeners();
  }

  void cancelGeneration() {
    _cancelToken?.cancel();
    _isLoading = false;
    notifyListeners();
  }

  void toggleActivityExpanded() {
    _activityExpanded = !_activityExpanded;
    notifyListeners();
  }

  void toggleStepExpanded(int index) {
    if (_expandedSteps.contains(index)) {
      _expandedSteps.remove(index);
    } else {
      _expandedSteps.add(index);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }
}
