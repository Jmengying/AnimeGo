import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/anime.dart';

class MaccmsType {
  final int id;
  final String name;
  MaccmsType({required this.id, required this.name});
}

class MaccmsArea {
  final String name;
  MaccmsArea({required this.name});
}

class MaccmsGenre {
  final String name;
  MaccmsGenre({required this.name});
}

class AnimeApiService {
  static const _timeout = Duration(seconds: 15);
  static const _headers = {'User-Agent': 'Mozilla/5.0'};

  // 缓存每个baseUrl对应的类型列表、地区列表和标签列表
  final Map<String, List<MaccmsType>> _typeCache = {};
  final Map<String, List<MaccmsArea>> _areaCache = {};
  final Map<String, List<MaccmsGenre>> _genreCache = {};

  /// 清除缓存（切换源时调用）
  void clearTypeCache() {
    _typeCache.clear();
    _areaCache.clear();
    _genreCache.clear();
  }

  /// 一次性获取所有筛选元数据（类型、地区、标签），共享API请求
  Future<void> _fetchAllMetadata(String baseUrl) async {
    if (_typeCache.containsKey(baseUrl)) return;
    try {
      final types = <int, MaccmsType>{};
      final areas = <String>{};
      final genres = <String>{};
      for (int pg = 1; pg <= 3; pg++) {
        final params = {'ac': 'list', 'pg': pg.toString()};
        final uri = Uri.parse(baseUrl).replace(queryParameters: params);
        final response = await http.get(uri, headers: _headers).timeout(_timeout);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['code'] == 1) {
            final list = data['list'] as List? ?? [];
            for (final item in list) {
              final tid = item['type_id'] as int? ?? 0;
              final tname = item['type_name']?.toString() ?? '';
              if (tid > 0 && tname.isNotEmpty && !types.containsKey(tid)) {
                types[tid] = MaccmsType(id: tid, name: tname);
              }
              final area = item['vod_area']?.toString() ?? '';
              if (area.isNotEmpty) areas.add(area);
              final cls = item['vod_class']?.toString() ?? '';
              if (cls.isNotEmpty) {
                for (final g in cls.split(RegExp(r'[,，]'))) {
                  final trimmed = g.trim();
                  if (trimmed.isNotEmpty) genres.add(trimmed);
                }
              }
            }
          }
        }
      }
      final tResult = types.values.toList()..sort((a, b) => a.id.compareTo(b.id));
      if (tResult.isNotEmpty) _typeCache[baseUrl] = tResult;
      final aResult = areas.map((a) => MaccmsArea(name: a)).toList()..sort((a, b) => a.name.compareTo(b.name));
      if (aResult.isNotEmpty) _areaCache[baseUrl] = aResult;
      final gResult = genres.map((g) => MaccmsGenre(name: g)).toList()..sort((a, b) => a.name.compareTo(b.name));
      if (gResult.isNotEmpty) _genreCache[baseUrl] = gResult;
    } catch (_) {}
  }

  Future<List<MaccmsType>> getTypeList(String baseUrl) async {
    await _fetchAllMetadata(baseUrl);
    return _typeCache[baseUrl] ?? [];
  }

  Future<List<MaccmsArea>> getAreaList(String baseUrl) async {
    await _fetchAllMetadata(baseUrl);
    return _areaCache[baseUrl] ?? [];
  }

  Future<List<MaccmsGenre>> getGenreList(String baseUrl) async {
    await _fetchAllMetadata(baseUrl);
    return _genreCache[baseUrl] ?? [];
  }

  Future<List<Anime>> _fetchAnime(String baseUrl,
      {String? wd, int pg = 1, int typeId = 0, String? area, String? year, String? genre}) async {
    try {
      final params = <String, String>{
        'ac': 'detail',
        'pg': pg.toString(),
      };
      if (wd != null && wd.isNotEmpty) params['wd'] = wd;
      if (typeId > 0) params['t'] = typeId.toString();
      if (area != null && area.isNotEmpty) params['area'] = area;
      if (year != null && year.isNotEmpty) params['year'] = year;
      if (genre != null && genre.isNotEmpty) {
        params['wd'] = wd != null && wd.isNotEmpty ? '$wd $genre' : genre;
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 1) {
          final list = data['list'] as List? ?? [];
          return list.map((item) => _parseAnime(item)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Anime _parseAnime(Map<String, dynamic> json) {
    final playUrl = json['vod_play_url']?.toString() ?? '';
    final sources = _parseEpisodeSources(playUrl);
    final episodes = sources.isNotEmpty ? sources.first.episodes : <Episode>[];
    return Anime(
      id: json['vod_id']?.toString() ?? '',
      title: json['vod_name']?.toString() ?? '',
      cover: json['vod_pic']?.toString() ?? '',
      description:
          json['vod_content']?.toString() ?? json['vod_blurb']?.toString() ?? '',
      type: json['vod_class']?.toString() ?? '',
      year: json['vod_year']?.toString() ?? '',
      status: json['vod_remarks']?.toString() ?? '',
      rating: json['vod_score']?.toString(),
      genres: (json['vod_class']?.toString() ?? '')
          .split(RegExp(r'[,，]'))
          .where((g) => g.isNotEmpty)
          .toList(),
      updateInfo: json['vod_remarks']?.toString(),
      episodes: episodes,
      episodeSources: sources,
    );
  }

  /// maccms 格式: 源名称#集1$url1#集2$url2$$$源名称#集1$url1#集2$url2
  /// 或: 集1$url1#集2$url2$$$集1$url1#集2$url2
  List<EpisodeSource> _parseEpisodeSources(String playUrl) {
    if (playUrl.isEmpty) return [];
    final sourceParts = playUrl.split(r'$$$');
    final List<EpisodeSource> sources = [];
    for (final sourcePart in sourceParts) {
      final segments = sourcePart.split('#');
      String sourceName = '播放源${sources.length + 1}';
      final List<Episode> episodes = [];
      for (int i = 0; i < segments.length; i++) {
        final seg = segments[i].trim();
        if (seg.isEmpty) continue;
        final idx = seg.indexOf('\$');
        if (idx > 0) {
          final title = seg.substring(0, idx).trim();
          final url = seg.substring(idx + 1).trim();
          if (title.isNotEmpty && url.isNotEmpty) {
            episodes.add(Episode(title: title, url: url));
          }
        } else if (i == 0 && !seg.contains('\$')) {
          // 没有$的第一段是源名称（如 "量子m3u8"、"暴风资源"）
          sourceName = seg;
        }
      }
      if (episodes.isNotEmpty) {
        sources.add(EpisodeSource(name: sourceName, episodes: episodes));
      }
    }
    return sources;
  }

  Future<List<Anime>> searchAnime(String baseUrl, String keyword,
      {int page = 1}) async {
    return _fetchAnime(baseUrl, wd: keyword, pg: page);
  }

  Future<List<Anime>> getRecommendAnime(String baseUrl) async {
    return _fetchAnime(baseUrl, pg: 1);
  }

  Future<List<Anime>> getLatestAnime(String baseUrl, {int page = 1}) async {
    return _fetchAnime(baseUrl, pg: page);
  }

  Future<List<Anime>> getAnimeListByTag(String baseUrl, String tag,
      {int page = 1}) async {
    if (tag.isEmpty) {
      return _fetchAnime(baseUrl, pg: page);
    }
    return _fetchAnime(baseUrl, wd: tag, pg: page);
  }

  /// 按分类获取动漫（使用typeId进行精确过滤）
  Future<List<Anime>> getAnimeByCategory(String baseUrl,
      {int typeId = 0,
      String area = '',
      String year = '',
      String genre = '',
      int page = 1}) async {
    return _fetchAnime(baseUrl,
        typeId: typeId,
        area: area.isNotEmpty ? area : null,
        year: year.isNotEmpty ? year : null,
        genre: genre.isNotEmpty ? genre : null,
        pg: page);
  }

  Future<Anime?> getAnimeDetail(String baseUrl, String id) async {
    try {
      final uri = Uri.parse(baseUrl)
          .replace(queryParameters: {'ac': 'detail', 'ids': id});
      final response = await http
          .get(uri, headers: _headers)
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 1) {
          final list = data['list'] as List? ?? [];
          if (list.isNotEmpty) return _parseAnime(list.first);
        }
      }
    } catch (_) {}
    return null;
  }
}
