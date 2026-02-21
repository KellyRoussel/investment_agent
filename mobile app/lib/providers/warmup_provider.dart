import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ContentItem {
  final String content;
  final String? label;
  final bool isTrivia;

  const ContentItem({
    required this.content,
    this.label,
    required this.isTrivia,
  });
}

const _fallbackQuotes = [
  ContentItem(
    content:
        'The stock market is a device for transferring money from the impatient to the patient.',
    label: '— Warren Buffett',
    isTrivia: false,
  ),
  ContentItem(
    content: 'Risk comes from not knowing what you\'re doing.',
    label: '— Warren Buffett',
    isTrivia: false,
  ),
  ContentItem(
    content:
        'The four most dangerous words in investing are: "This time it\'s different."',
    label: '— Sir John Templeton',
    isTrivia: false,
  ),
  ContentItem(
    content: 'In investing, what is comfortable is rarely profitable.',
    label: '— Robert Arnott',
    isTrivia: false,
  ),
  ContentItem(
    content:
        'The individual investor should act consistently as an investor and not as a speculator.',
    label: '— Benjamin Graham',
    isTrivia: false,
  ),
];

class WarmupProvider extends ChangeNotifier {
  final String _baseUrl;

  bool _isBackendReady = false;
  ContentItem? _currentContent;
  int _failCount = 0;
  bool _isTrivia = false;

  Timer? _pollingTimer;
  Timer? _contentTimer;

  final _random = Random();
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  WarmupProvider(this._baseUrl);

  bool get isBackendReady => _isBackendReady;
  ContentItem? get currentContent => _currentContent;
  int get failCount => _failCount;

  void start() {
    _fetchContent();
    _checkBackend();
    _pollingTimer =
        Timer.periodic(const Duration(seconds: 15), (_) => _checkBackend());
    _contentTimer =
        Timer.periodic(const Duration(seconds: 8), (_) => _fetchContent());
  }

  Future<void> _checkBackend() async {
    final url = '$_baseUrl/health';
    print('=== WARMUP: pinging $url');
    try {
      // Any HTTP response (even 404) means the server is up and accepting connections.
      // Only network-level errors (timeout, connection refused) mean it's still cold-starting.
      final response = await _dio.get(
        url,
        options: Options(validateStatus: (_) => true),
      );
      print('=== WARMUP: got ${response.statusCode} — backend ready');
      _isBackendReady = true;
      _pollingTimer?.cancel();
      _contentTimer?.cancel();
      notifyListeners();
    } catch (e) {
      print('=== WARMUP: health check failed — $e');
      _failCount++;
      notifyListeners();
    }
  }

  Future<void> _fetchContent() async {
    _isTrivia = !_isTrivia;
    if (_isTrivia) {
      await _fetchTrivia();
    } else {
      await _fetchQuote();
    }
  }

  Future<void> _fetchQuote() async {
    try {
      final response = await _dio.get(
        'https://api.quotable.io/random',
        queryParameters: {'tags': 'business'},
      );
      _currentContent = ContentItem(
        content: response.data['content'] as String,
        label: '— ${response.data['author']}',
        isTrivia: false,
      );
    } catch (_) {
      _currentContent = _fallbackQuotes[_random.nextInt(_fallbackQuotes.length)];
    }
    notifyListeners();
  }

  Future<void> _fetchTrivia() async {
    try {
      final response = await _dio.get(
        'https://opentdb.com/api.php',
        queryParameters: {'amount': '1', 'category': '18', 'type': 'multiple'},
      );
      final result =
          (response.data['results'] as List).first as Map<String, dynamic>;
      _currentContent = ContentItem(
        content: _decodeHtml(result['question'] as String),
        label: _decodeHtml(result['correct_answer'] as String),
        isTrivia: true,
      );
    } catch (_) {
      _isTrivia = false;
      await _fetchQuote();
      return;
    }
    notifyListeners();
  }

  String _decodeHtml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&ldquo;', '\u201C')
        .replaceAll('&rdquo;', '\u201D')
        .replaceAll('&ndash;', '\u2013')
        .replaceAll('&mdash;', '\u2014');
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _contentTimer?.cancel();
    _dio.close();
    super.dispose();
  }
}
