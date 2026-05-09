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

class AnimeApiService {
  static const _timeout = Duration(seconds: 15);
  static const _headers = {'User-Agent': 'Mozilla/5.0'};

  // 缓存每个baseUrl对应的类型列表和地区列表
  final Map<String, List<MaccmsType>> _typeCache = {};
  final Map<String, List<MaccmsArea>> _areaCache = {};

  /// 清除缓存（切换源时调用）
  void clearTypeCache() {
    _typeCache.clear();
    _areaCache.clear();
  }

  /// 获取maccms分类列表：从实际数据中提取type_id和type_name
  Future<List<MaccmsType>> getTypeList(String baseUrl) async {
    if (_typeCache.containsKey(baseUrl)) return _typeCache[baseUrl]!;
    try {
      // 多抓几页来获取更多类型
      final types = <int, MaccmsType>{};
      for (int pg = 1; pg <= 3; pg++) {
        final params = {'ac': 'detail', 'pg': pg.toString()};
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
            }
          }
        }
      }
      final result = types.values.toList()..sort((a, b) => a.id.compareTo(b.id));
      if (result.isNotEmpty) {
        _typeCache[baseUrl] = result;
      }
      return result;
    } catch (_) {}
    return [];
  }

  /// 获取maccms地区列表：从实际数据中提取vod_area
  Future<List<MaccmsArea>> getAreaList(String baseUrl) async {
    if (_areaCache.containsKey(baseUrl)) return _areaCache[baseUrl]!;
    try {
      final areas = <String>{};
      for (int pg = 1; pg <= 3; pg++) {
        final params = {'ac': 'detail', 'pg': pg.toString()};
        final uri = Uri.parse(baseUrl).replace(queryParameters: params);
        final response = await http.get(uri, headers: _headers).timeout(_timeout);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['code'] == 1) {
            final list = data['list'] as List? ?? [];
            for (final item in list) {
              final area = item['vod_area']?.toString() ?? '';
              if (area.isNotEmpty) areas.add(area);
            }
          }
        }
      }
      final result = areas.map((a) => MaccmsArea(name: a)).toList()..sort((a, b) => a.name.compareTo(b.name));
      if (result.isNotEmpty) {
        _areaCache[baseUrl] = result;
      }
      return result;
    } catch (_) {}
    return [];
  }

  Future<List<Anime>> _fetchAnime(String baseUrl,
      {String? wd, int pg = 1, int typeId = 0, String? area, String? year}) async {
    try {
      final params = <String, String>{
        'ac': 'detail',
        'pg': pg.toString(),
      };
      if (wd != null && wd.isNotEmpty) params['wd'] = wd;
      if (typeId > 0) params['t'] = typeId.toString();
      if (area != null && area.isNotEmpty) params['area'] = area;
      if (year != null && year.isNotEmpty) params['year'] = year;

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
      int page = 1}) async {
    return _fetchAnime(baseUrl,
        typeId: typeId,
        area: area.isNotEmpty ? area : null,
        year: year.isNotEmpty ? year : null,
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
