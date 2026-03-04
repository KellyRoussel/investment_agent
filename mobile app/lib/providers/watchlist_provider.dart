import 'package:flutter/foundation.dart';
import '../models/watchlist.dart';
import '../services/watchlist_service.dart';

class WatchlistProvider extends ChangeNotifier {
  final WatchlistService _service;

  List<WatchlistItem> _items = [];
  bool _isLoading = false;
  String? _error;

  WatchlistProvider(this._service);

  List<WatchlistItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<WatchlistItem> get highPriority =>
      _items.where((i) => i.priority == 'high').toList();
  List<WatchlistItem> get normalPriority =>
      _items.where((i) => i.priority == 'normal' || i.priority == null).toList();
  List<WatchlistItem> get lowPriority =>
      _items.where((i) => i.priority == 'low').toList();

  Future<void> fetchWatchlist() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.getWatchlist();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(WatchlistItemCreate data) async {
    try {
      final item = await _service.addItem(data);
      _items = [..._items, item];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      await _service.removeItem(itemId);
      _items = _items.where((i) => i.id != itemId).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
