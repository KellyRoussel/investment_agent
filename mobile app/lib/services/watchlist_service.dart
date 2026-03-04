import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/watchlist.dart';

class WatchlistService {
  final ApiClient _api;

  WatchlistService(this._api);

  Future<List<WatchlistItem>> getWatchlist() async {
    final response = await _api.get(ApiConstants.watchlist);
    final list = response.data as List;
    return list
        .map((e) => WatchlistItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WatchlistItem> addItem(WatchlistItemCreate data) async {
    final response = await _api.post(ApiConstants.watchlist, data: data.toJson());
    return WatchlistItem.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> removeItem(String itemId) async {
    await _api.delete(ApiConstants.watchlistItem(itemId));
  }
}
