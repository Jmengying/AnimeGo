import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/watch_record.dart';

class LocalStorageService {
  static const String _historyPrefix = 'watch_history_';
  static const String _favoritesPrefix = 'favorites_';
  static const String _searchHistoryKey = 'search_history';

  // Watch History
  Future<void> saveWatchRecord(String userId, WatchRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _historyPrefix + userId;
    final recordsStr = prefs.getString(key) ?? '[]';
    final List<dynamic> records = json.decode(recordsStr);

    // Remove existing record for same episode
    records.removeWhere((r) =>
        r['animeId'] == record.animeId && r['episodeUrl'] == record.episodeUrl);

    // Add new record at the beginning
    records.insert(0, {
      'animeId': record.animeId,
      'animeTitle': record.animeTitle,
      'animeCover': record.animeCover,
      'episodeTitle': record.episodeTitle,
      'episodeUrl': record.episodeUrl,
      'progress': record.progress,
      'duration': record.duration,
      'watchedAt': DateTime.now().toIso8601String(),
    });

    // Keep only last 100 records
    if (records.length > 100) {
      records.removeRange(100, records.length);
    }

    await prefs.setString(key, json.encode(records));
  }

  Future<List<WatchRecord>> getWatchHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _historyPrefix + userId;
    final recordsStr = prefs.getString(key) ?? '[]';
    final List<dynamic> records = json.decode(recordsStr);

    return records.map((r) => WatchRecord(
      animeId: r['animeId'] ?? '',
      animeTitle: r['animeTitle'] ?? '',
      animeCover: r['animeCover'] ?? '',
      episodeTitle: r['episodeTitle'] ?? '',
      episodeUrl: r['episodeUrl'] ?? '',
      progress: r['progress'] ?? 0,
      duration: r['duration'] ?? 0,
      watchedAt: DateTime.tryParse(r['watchedAt'] ?? '') ?? DateTime.now(),
    )).toList();
  }

  Future<void> clearWatchHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyPrefix + userId);
  }

  // Favorites
  Future<void> toggleFavorite(String userId, Map<String, dynamic> animeData) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _favoritesPrefix + userId;
    final favsStr = prefs.getString(key) ?? '[]';
    final List<dynamic> favs = json.decode(favsStr);

    final index = favs.indexWhere((f) => f['id'] == animeData['id']);
    if (index >= 0) {
      favs.removeAt(index);
    } else {
      favs.add({...animeData, 'favoritedAt': DateTime.now().toIso8601String()});
    }

    await prefs.setString(key, json.encode(favs));
  }

  Future<bool> isFavorite(String userId, String animeId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _favoritesPrefix + userId;
    final favsStr = prefs.getString(key) ?? '[]';
    final List<dynamic> favs = json.decode(favsStr);
    return favs.any((f) => f['id'] == animeId);
  }

  Future<List<Map<String, dynamic>>> getFavorites(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _favoritesPrefix + userId;
    final favsStr = prefs.getString(key) ?? '[]';
    final List<dynamic> favs = json.decode(favsStr);
    return favs.cast<Map<String, dynamic>>();
  }

  // Search History
  Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_searchHistoryKey) ?? [];
  }

  Future<void> addSearchHistory(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_searchHistoryKey) ?? [];
    history.remove(keyword);
    history.insert(0, keyword);
    if (history.length > 20) history.removeRange(20, history.length);
    await prefs.setStringList(_searchHistoryKey, history);
  }

  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
  }
}
