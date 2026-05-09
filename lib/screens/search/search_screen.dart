import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/anime_provider.dart';
import '../../providers/source_provider.dart';
import '../../providers/history_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/anime_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _keyword = '';
  int _currentPage = 1;
  bool _lastPageEmpty = false;
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await ref.read(storageServiceProvider).getSearchHistory();
    if (mounted) setState(() => _searchHistory = history);
  }

  Future<void> _saveHistory(String keyword) async {
    await ref.read(storageServiceProvider).addSearchHistory(keyword);
    await _loadHistory();
  }

  Future<void> _clearHistory() async {
    await ref.read(storageServiceProvider).clearSearchHistory();
    if (mounted) setState(() => _searchHistory.clear());
  }

  void _search(String keyword) {
    if (keyword.trim().isEmpty) return;
    setState(() { _keyword = keyword.trim(); _currentPage = 1; _lastPageEmpty = false; });
    _saveHistory(keyword.trim());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeSite = ref.watch(activeSiteProvider);
    final activeWh = ref.watch(activeWarehouseProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: '搜索动漫...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _keyword = '');
                            },
                          )
                        : null,
                  ),
                  onSubmitted: _search,
                  onChanged: (v) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _search(_searchController.text),
                child: const Text('搜索'),
              ),
            ],
          ),
        ),
        // 当前搜索源指示
        if (activeSite != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.cloud_outlined, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '搜索源: ${activeWh?.name ?? ''} - ${activeSite.name}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        if (activeSite == null)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Text('请先在首页选择数据源', style: TextStyle(color: AppTheme.textSecondary)),
          ),
        if (activeSite != null)
          Expanded(
            child: _keyword.isEmpty ? _buildHistory() : _buildResults(),
          ),
      ],
    );
  }

  Widget _buildHistory() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (_searchHistory.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('搜索历史', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              TextButton(onPressed: _clearHistory, child: const Text('清空', style: TextStyle(fontSize: 12))),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchHistory.map((h) {
              return GestureDetector(
                onTap: () { _searchController.text = h; _search(h); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(16)),
                  child: Text(h, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        const Text('热门搜索', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['鬼灭之刃', '咒术回战', '进击的巨人', '间谍过家家', '电锯人', '海贼王', '火影忍者', '死神', '名侦探柯南', '龙珠'].map((h) {
            return GestureDetector(
              onTap: () { _searchController.text = h; _search(h); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(16)),
                child: Text(h, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResults() {
    final resultsAsync = ref.watch(searchAnimeProvider('$_keyword|$_currentPage'));

    return Column(
      children: [
        Expanded(
          child: resultsAsync.when(
            data: (animes) {
              if (animes.isEmpty) {
                if (_currentPage > 1 && !_lastPageEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _lastPageEmpty = true);
                  });
                }
                if (_currentPage == 1) {
                  return const Center(child: Text('没有找到相关动漫', style: TextStyle(color: AppTheme.textSecondary)));
                }
                return const Center(child: Text('没有更多结果', style: TextStyle(color: AppTheme.textSecondary)));
              } else {
                if (_lastPageEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _lastPageEmpty = false);
                  });
                }
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: getCrossAxisCount(context),
                  childAspectRatio: 0.55,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: animes.length,
                itemBuilder: (context, index) => AnimeCard(anime: animes[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 48, color: AppTheme.textSecondary),
                  const SizedBox(height: 12),
                  Text('搜索失败: $e', style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ),
        ),
        // Pagination controls
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                icon: const Icon(Icons.chevron_left),
                color: AppTheme.textPrimary,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('第 $_currentPage 页', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
              ),
              IconButton(
                onPressed: _lastPageEmpty ? null : () => setState(() => _currentPage++),
                icon: const Icon(Icons.chevron_right),
                color: AppTheme.textPrimary,
              ),
            ],
          ),
        ),
      ],
    );
  }

}

