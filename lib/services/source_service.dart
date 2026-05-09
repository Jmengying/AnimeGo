import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/source_site.dart';
import '../models/source_warehouse.dart';
import '../models/source_subscription.dart';

class SourceService {
  static const String _subsKey = 'source_subscriptions';
  static const String _activeSubKey = 'active_subscription_id';
  static const String _activeWhKey = 'active_warehouse_id';
  static const String _activeSiteKey = 'active_site_id';

  // 内置默认数据源（直接可用的maccms API）
  static const List<Map<String, String>> defaultMaccmsSources = [
    {'name': '樱花动漫', 'url': 'https://www.yhdm365.com/api.php/provide/vod/'},
    {'name': '魔都动漫', 'url': 'https://caiji.moduapi.cc/api.php/provide/vod/'},
    {'name': '非凡资源', 'url': 'https://api.ffzyapi.com/api.php/provide/vod/'},
    {'name': '暴风资源', 'url': 'https://bfzyapi.com/api.php/provide/vod/'},
    {'name': '樱花动漫2', 'url': 'https://www.yhdm.cc/api.php/provide/vod/'},
  ];

  // 内置TVBox订阅链接
  static const List<Map<String, String>> builtinSubscriptions = [
    {'name': '小盒子', 'url': 'http://xhztv.top/dc'},
    {'name': 'NXOG源', 'url': 'https://tv.nxog.top/m'},
  ];

  List<SourceSubscription> _subscriptions = [];
  String _activeSubId = '';
  String _activeWhId = '';
  String _activeSiteId = '';

  // === Getters ===

  List<SourceSubscription> get subscriptions => _subscriptions;

  SourceSubscription? get activeSubscription {
    try {
      return _subscriptions.firstWhere((s) => s.id == _activeSubId);
    } catch (_) {
      return _subscriptions.isNotEmpty ? _subscriptions.first : null;
    }
  }

  SourceWarehouse? get activeWarehouse {
    final sub = activeSubscription;
    if (sub == null) return null;
    try {
      return sub.warehouses.firstWhere((w) => w.id == _activeWhId);
    } catch (_) {
      return sub.warehouses.isNotEmpty ? sub.warehouses.first : null;
    }
  }

  SourceSite? get activeSite {
    final wh = activeWarehouse;
    if (wh == null) return null;
    try {
      return wh.maccmsSites.firstWhere((s) => s.id == _activeSiteId);
    } catch (_) {
      return wh.maccmsSites.isNotEmpty ? wh.maccmsSites.first : null;
    }
  }

  String? get activeApiUrl => activeSite?.apiUrl;

  List<SourceSite> get currentWarehouseSites =>
      activeWarehouse?.maccmsSites ?? [];

  List<SourceSite> get currentSubscriptionAllSites =>
      activeSubscription?.allMaccmsSites ?? [];

  // === Init ===

  /// 快速初始化：加载缓存数据，不阻塞
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final subsStr = prefs.getString(_subsKey);

    if (subsStr != null) {
      final list = json.decode(subsStr) as List;
      _subscriptions =
          list.map((e) => SourceSubscription.fromJson(e)).toList();
    }

    _activeSubId = prefs.getString(_activeSubKey) ?? '';
    _activeWhId = prefs.getString(_activeWhKey) ?? '';
    _activeSiteId = prefs.getString(_activeSiteKey) ?? '';
    _autoSelectIfEmpty();
    await _saveIds();
  }

  /// 是否需要导入（首次启动或没有可用源）
  bool get needsImport =>
      _subscriptions.isEmpty || activeSite == null;

  /// 完整导入：默认maccms源 + TVBox订阅
  Future<void> importAllBuiltins() async {
    // 1. 添加直接可用的maccms源
    final defaultSites = defaultMaccmsSources
        .map((s) => SourceSite(
              id: 'maccms_${s['name']}_${DateTime.now().millisecondsSinceEpoch}',
              name: s['name']!,
              apiUrl: s['url']!,
              type: 1,
            ))
        .toList();
    final defaultWarehouse = SourceWarehouse(
      id: 'default_wh',
      name: '默认源',
      url: '',
      sites: defaultSites,
    );
    final defaultSub = SourceSubscription(
      id: 'default_sub',
      name: '内置源',
      url: '',
      warehouses: [defaultWarehouse],
      isBuiltIn: true,
    );

    // 2. 导入TVBox订阅（带容错和超时）
    final List<SourceSubscription> tvboxSubs = [];
    for (final builtin in builtinSubscriptions) {
      try {
        final sub = await importSubscription(builtin['url']!, name: builtin['name'])
            .timeout(const Duration(seconds: 15), onTimeout: () {
          return SourceSubscription(
            id: '', name: builtin['name']!, url: builtin['url']!,
          );
        });
        if (sub.warehouses.isNotEmpty) {
          tvboxSubs.add(SourceSubscription(
            id: 'builtin_${tvboxSubs.length}',
            name: builtin['name']!,
            url: builtin['url']!,
            warehouses: sub.warehouses,
            isBuiltIn: true,
          ));
        }
        // 每导入一个就保存，防止中途退出丢失数据
        _subscriptions = [defaultSub, ...tvboxSubs];
        _autoSelectIfEmpty();
        await _save();
        await _saveIds();
      } catch (_) {
        continue;
      }
    }

    // 3. 合并：默认源 + TVBox订阅（去重已有的）
    _subscriptions = [defaultSub];
    for (final sub in tvboxSubs) {
      if (!_subscriptions.any((s) => s.url == sub.url)) {
        _subscriptions.add(sub);
      }
    }

    _autoSelectIfEmpty();
    await _save();
    await _saveIds();
  }

  void _autoSelectIfEmpty() {
    if (_activeSiteId.isEmpty || activeSite == null) {
      final sub = activeSubscription;
      if (sub != null) {
        _activeSubId = sub.id;
        final wh = sub.warehouses.isNotEmpty ? sub.warehouses.first : null;
        if (wh != null) {
          _activeWhId = wh.id;
          final site = wh.maccmsSites.isNotEmpty ? wh.maccmsSites.first : null;
          if (site != null) {
            _activeSiteId = site.id;
          }
        }
      }
    }
  }

  // === JSON解析（兼容注释） ===

  dynamic _parseJsonTolerant(String body) {
    // 移除注释行（//开头）和行内注释
    final cleaned = body
        .split('\n')
        .map((line) {
          final trimmed = line.trimLeft();
          if (trimmed.startsWith('//')) return '';
          // 移除行内 // 注释（但不影响URL中的://）
          final idx = line.indexOf('//');
          if (idx > 0) {
            // 检查前面是否有 :（如 https://），有的话跳过
            final before = line.substring(0, idx);
            if (!before.endsWith(':') && !before.endsWith(':/')) {
              return line.substring(0, idx);
            }
          }
          return line;
        })
        .join('\n');
    return json.decode(cleaned);
  }

  // === 导入TVBox订阅 ===

  Future<SourceSubscription> importSubscription(String subUrl, {String? name}) async {
    // Step 1: 获取订阅JSON
    final subResp = await http.get(
      Uri.parse(subUrl),
      headers: {'User-Agent': 'Mozilla/5.0'},
    ).timeout(const Duration(seconds: 8));

    if (subResp.statusCode != 200) {
      return SourceSubscription(
        id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
        name: name ?? subUrl,
        url: subUrl,
      );
    }

    final subJson = _parseJsonTolerant(subResp.body);
    final List<SourceWarehouse> warehouses = [];

    // TVBox多仓格式: {"urls": [{"name": "...", "url": "..."}, ...]}
    // 单仓格式: {"sites": [...]}
    List<dynamic> urlList = [];
    if (subJson is Map && subJson.containsKey('urls')) {
      urlList = subJson['urls'] as List;
    } else if (subJson is Map && subJson.containsKey('sites')) {
      urlList = [{'name': name ?? 'direct', 'url': subUrl, 'config': subJson}];
    }

    // Step 2: 遍历每个仓库
    for (final item in urlList) {
      final whName = item['name']?.toString() ?? '未命名';
      final whUrl = item['url']?.toString() ?? '';

      if (whUrl.isEmpty) continue;

      try {
        Map<String, dynamic> config;
        if (item is Map && item.containsKey('config')) {
          config = item['config'] as Map<String, dynamic>;
        } else {
          final configResp = await http.get(
            Uri.parse(whUrl),
            headers: {'User-Agent': 'Mozilla/5.0'},
          ).timeout(const Duration(seconds: 5));
          if (configResp.statusCode != 200) continue;
          config = _parseJsonTolerant(configResp.body);
        }

        final sitesRaw = config['sites'] as List? ?? [];
        final List<SourceSite> sites = [];

        for (final site in sitesRaw) {
          final siteType = site['type'] ?? 0;
          final siteApi = site['api']?.toString() ?? '';
          final siteName = site['name']?.toString() ?? '';
          final siteExt = site['ext']?.toString();

          if (siteApi.isEmpty) continue;

          final apiUrl = siteType == 1 && siteApi.contains('api.php')
              ? (siteApi.endsWith('/') ? siteApi : '$siteApi/')
              : siteApi;

          sites.add(SourceSite(
            id: 'site_${DateTime.now().millisecondsSinceEpoch}_${sites.length}',
            name: siteName,
            apiUrl: apiUrl,
            type: siteType,
            ext: siteExt,
          ));
        }

        if (sites.isNotEmpty) {
          warehouses.add(SourceWarehouse(
            id: 'wh_${DateTime.now().millisecondsSinceEpoch}_${warehouses.length}',
            name: whName,
            url: whUrl,
            sites: sites,
          ));
        }
      } catch (_) {
        continue;
      }
    }

    return SourceSubscription(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? subUrl,
      url: subUrl,
      warehouses: warehouses,
    );
  }

  // === 切换源 ===

  Future<void> setActiveSubscription(String id) async {
    _activeSubId = id;
    // 自动选第一个仓库和站点
    final sub = activeSubscription;
    if (sub != null && sub.warehouses.isNotEmpty) {
      _activeWhId = sub.warehouses.first.id;
      final sites = sub.warehouses.first.maccmsSites;
      _activeSiteId = sites.isNotEmpty ? sites.first.id : '';
    }
    await _saveIds();
  }

  Future<void> setActiveWarehouse(String subId, String warehouseId) async {
    _activeSubId = subId;
    _activeWhId = warehouseId;
    // 自动选第一个可用站点
    final wh = activeWarehouse;
    if (wh != null) {
      final sites = wh.maccmsSites;
      _activeSiteId = sites.isNotEmpty ? sites.first.id : '';
    }
    await _saveIds();
  }

  Future<void> setActiveSite(String subId, String warehouseId, String siteId) async {
    _activeSubId = subId;
    _activeWhId = warehouseId;
    _activeSiteId = siteId;
    await _saveIds();
  }

  // === 测试 ===

  Future<bool> testSource(String apiUrl) async {
    try {
      final uri = Uri.parse(apiUrl).replace(queryParameters: {'ac': 'detail', 'pg': '1'});
      final response = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0',
      }).timeout(const Duration(seconds: 5));
      return response.statusCode == 200 && response.body.contains('"code":1');
    } catch (_) {
      return false;
    }
  }

  // === 手动添加订阅 ===

  Future<void> addSubscription(SourceSubscription sub) async {
    // 去重
    if (!_subscriptions.any((s) => s.url == sub.url)) {
      _subscriptions.add(sub);
      await _save();
    }
  }

  Future<void> removeSubscription(String id) async {
    _subscriptions.removeWhere((s) => s.id == id);
    if (_activeSubId == id) {
      _activeSubId = _subscriptions.isNotEmpty ? _subscriptions.first.id : '';
      _autoSelectIfEmpty();
    }
    await _save();
  }

  Future<void> refreshSubscription(String subscriptionId) async {
    final idx = _subscriptions.indexWhere((s) => s.id == subscriptionId);
    if (idx < 0) return;
    final old = _subscriptions[idx];
    try {
      final refreshed = await importSubscription(old.url, name: old.name);
      _subscriptions[idx] = SourceSubscription(
        id: old.id,
        name: old.name,
        url: old.url,
        warehouses: refreshed.warehouses,
        isBuiltIn: old.isBuiltIn,
      );
      await _save();
    } catch (_) {}
  }

  // === 保存 ===

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _subsKey, json.encode(_subscriptions.map((s) => s.toJson()).toList()));
  }

  Future<void> _saveIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSubKey, _activeSubId);
    await prefs.setString(_activeWhKey, _activeWhId);
    await prefs.setString(_activeSiteKey, _activeSiteId);
  }
}
