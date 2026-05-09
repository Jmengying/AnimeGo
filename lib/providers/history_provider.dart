import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/watch_record.dart';
import '../services/local_storage_service.dart';
import 'auth_provider.dart';

final storageServiceProvider = Provider<LocalStorageService>((ref) => LocalStorageService());

final watchHistoryProvider = FutureProvider<List<WatchRecord>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final email = user['email'] ?? '';
  if (email.isEmpty) return [];
  return ref.watch(storageServiceProvider).getWatchHistory(email);
});

final favoritesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final email = user['email'] ?? '';
  if (email.isEmpty) return [];
  return ref.watch(storageServiceProvider).getFavorites(email);
});
