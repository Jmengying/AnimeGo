import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/anime.dart';
import '../services/anime_api_service.dart';
import 'source_provider.dart';

final animeApiServiceProvider = Provider<AnimeApiService>((ref) => AnimeApiService());

String _getBaseUrl(Ref ref) {
  ref.watch(sourceVersionProvider);
  return ref.read(sourceServiceProvider).activeApiUrl ?? '';
}

/// maccms类型列表（从当前源的API动态获取）
final typeListProvider = FutureProvider<List<MaccmsType>>((ref) {
  final baseUrl = _getBaseUrl(ref);
  if (baseUrl.isEmpty) return Future.value([]);
  return ref.read(animeApiServiceProvider).getTypeList(baseUrl);
});

/// maccms地区列表（从当前源的API动态获取）
final areaListProvider = FutureProvider<List<MaccmsArea>>((ref) {
  final baseUrl = _getBaseUrl(ref);
  if (baseUrl.isEmpty) return Future.value([]);
  return ref.read(animeApiServiceProvider).getAreaList(baseUrl);
});

/// maccms标签列表（从当前源的API动态获取）
final genreListProvider = FutureProvider<List<MaccmsGenre>>((ref) {
  final baseUrl = _getBaseUrl(ref);
  if (baseUrl.isEmpty) return Future.value([]);
  return ref.read(animeApiServiceProvider).getGenreList(baseUrl);
});

final recommendAnimeProvider = FutureProvider<List<Anime>>((ref) {
  final baseUrl = _getBaseUrl(ref);
  if (baseUrl.isEmpty) return Future.value([]);
  return ref.read(animeApiServiceProvider).getRecommendAnime(baseUrl);
});

final latestAnimeProvider = FutureProvider<List<Anime>>((ref) {
  final baseUrl = _getBaseUrl(ref);
  if (baseUrl.isEmpty) return Future.value([]);
  return ref.read(animeApiServiceProvider).getLatestAnime(baseUrl);
});

final animeListByTagProvider = FutureProvider.family<List<Anime>, String>((ref, tag) {
  final baseUrl = _getBaseUrl(ref);
  if (baseUrl.isEmpty) return Future.value([]);
  return ref.read(animeApiServiceProvider).getAnimeListByTag(baseUrl, tag);
});

/// 分类筛选：key格式为 "typeId|area|year|genre|page"
final categoryAnimeProvider = FutureProvider.family<List<Anime>, String>((ref, key) {
  final baseUrl = _getBaseUrl(ref);
  if (baseUrl.isEmpty) return Future.value([]);
  final parts = key.split('|');
  final typeId = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
  final area = parts.length > 1 ? parts[1] : '';
  final year = parts.length > 2 ? parts[2] : '';
  final genre = parts.length > 3 ? parts[3] : '';
  final page = int.tryParse(parts.length > 4 ? parts[4] : '1') ?? 1;
  return ref.read(animeApiServiceProvider).getAnimeByCategory(
    baseUrl,
    typeId: typeId,
    area: area,
    year: year,
    genre: genre,
    page: page,
  );
});

final animeDetailProvider = FutureProvider.family<Anime?, String>((ref, id) {
  final baseUrl = _getBaseUrl(ref);
  if (baseUrl.isEmpty) return Future.value(null);
  return ref.read(animeApiServiceProvider).getAnimeDetail(baseUrl, id);
});

/// 搜索：key格式为 "keyword|page"
final searchAnimeProvider = FutureProvider.family<List<Anime>, String>((ref, key) {
  final parts = key.split('|');
  final keyword = parts.isNotEmpty ? parts[0] : '';
  final page = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
  if (keyword.isEmpty) return Future.value([]);
  final baseUrl = _getBaseUrl(ref);
  if (baseUrl.isEmpty) return Future.value([]);
  return ref.read(animeApiServiceProvider).searchAnime(baseUrl, keyword, page: page);
});
