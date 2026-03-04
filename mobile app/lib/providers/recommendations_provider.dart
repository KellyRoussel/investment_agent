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
  String? _reportId;
  List<InvestmentSuggestion> _suggestions = [];
  List<String> _availableModels = [];
  String _selectedModel = 'gpt-5-mini';

  RecommendationsProvider(this._service) {
    _loadAvailableModels();
  }

  List<WorkflowStep> get workflowSteps => _workflowSteps;
  String? get recommendation => _recommendation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get activityExpanded => _activityExpanded;
  Set<int> get expandedSteps => _expandedSteps;
  int get completedSteps =>
      _workflowSteps.where((s) => s.status == WorkflowStepStatus.completed).length;
  WorkflowCost? get workflowCost => _workflowCost;
  String? get reportId => _reportId;
  List<InvestmentSuggestion> get suggestions => _suggestions;
  bool get hasSuggestions => _suggestions.isNotEmpty;
  List<String> get availableModels => _availableModels;
  String get selectedModel => _selectedModel;

  void selectModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

  Future<void> _loadAvailableModels() async {
    try {
      final data = await _service.fetchAvailableModels();
      _availableModels = List<String>.from(data['models'] as List);
      notifyListeners();
    } catch (_) {
      // Non-blocking — model selector stays hidden if the call fails
    }
  }

  static const _stepNames = [
    'Portfolio Review',
    'Macro & Sector Scan',
    'Opportunity Research',
  ];

  Future<void> generateRecommendation({required double budgetEur}) async {
    _isLoading = true;
    _error = null;
    _recommendation = null;
    _workflowCost = null;
    _toolCallIdCounter = 0;
    _currentStep = null;
    _reportId = null;
    _suggestions = [];
    _expandedSteps.clear();
    _activityExpanded = true;

    // 3 backend steps + 1 synthetic "Decision & Thesis" step
    _workflowSteps = [
      ...List.generate(
        3,
        (i) => WorkflowStep(step: i + 1, name: _stepNames[i]),
      ),
      WorkflowStep(step: 4, name: 'Decision & Thesis'),
    ];
    notifyListeners();

    _cancelToken = CancelToken();

    try {
      final stream = _service.streamRecommendation(_cancelToken!, budgetEur: budgetEur, model: _selectedModel);
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
      case WorkflowStartEvent(:final reportId):
        _reportId = reportId;

      case StepStartEvent(:final step, :final stepName):
        final idx = step - 1;
        if (idx >= 0 && idx < _workflowSteps.length) {
          _workflowSteps[idx] = WorkflowStep(
            step: step,
            name: stepName.isNotEmpty ? stepName : _workflowSteps[idx].name,
            status: WorkflowStepStatus.inProgress,
            toolCalls: _workflowSteps[idx].toolCalls,
          );
          _currentStep = idx;
          _expandedSteps.add(idx);
        }

      case StepCompleteEvent(:final step, :final result):
        final idx = step - 1;
        if (idx >= 0 && idx < _workflowSteps.length) {
          _workflowSteps[idx] = WorkflowStep(
            step: step,
            name: _workflowSteps[idx].name,
            status: WorkflowStepStatus.completed,
            summary: result,
            toolCalls: _workflowSteps[idx].toolCalls,
          );
        }

      case ToolCallEvent(:final tool, :final inputs):
        if (_currentStep != null && _currentStep! < _workflowSteps.length) {
          final query = inputs.isNotEmpty ? inputs.values.first.toString() : '';
          _workflowSteps[_currentStep!].toolCalls.add(
            ToolCall(
              id: _toolCallIdCounter++,
              toolName: tool,
              query: query,
            ),
          );
        }

      case TokenEvent():
        break; // No-op: token streaming not displayed at this time

      case FinalReportEvent(:final content):
        _recommendation = content;
        // Mark step 4 (Decision & Thesis) as completed
        if (_workflowSteps.length >= 4) {
          _workflowSteps[3] = WorkflowStep(
            step: 4,
            name: 'Decision & Thesis',
            status: WorkflowStepStatus.completed,
          );
        }
        _isLoading = false;

      case InvestmentSuggestionsEvent(:final suggestions):
        _suggestions = suggestions;

      case WorkflowCompleteEvent(
          :final tokensInput,
          :final tokensCached,
          :final tokensOutput,
          :final costUsd,
          :final model,
        ):
        _workflowCost = WorkflowCost(
          tokensInput: tokensInput,
          tokensCached: tokensCached,
          tokensOutput: tokensOutput,
          costUsd: costUsd,
          model: model,
        );

      case ErrorEvent(:final message):
        _error = message;
        _isLoading = false;
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
