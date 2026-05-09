import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/anime_provider.dart';
import '../../providers/source_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/anime_card.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  static const List<String> _years = [
    '全部', '2026', '2025', '2024', '2023', '2022', '2021', '2020',
    '2019', '2018', '2017', '2016', '2015',
  ];

  int _selectedTypeId = 0;
  String _selectedArea = '全部';
  String _selectedYear = '全部';
  int _currentPage = 1;
  bool _expanded = true;
  bool _lastPageEmpty = false;

  @override
  Widget build(BuildContext context) {
    final activeSite = ref.watch(activeSiteProvider);
    final typeListAsync = ref.watch(typeListProvider);
    final areaListAsync = ref.watch(areaListProvider);

    final area = _selectedArea == '全部' ? '' : _selectedArea;
    final year = _selectedYear == '全部' ? '' : _selectedYear;
    final categoryKey = '$_selectedTypeId|$area|$year|$_currentPage';
    final animeListAsync = ref.watch(categoryAnimeProvider(categoryKey));

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('分类浏览'),
          actions: [
            IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
              tooltip: _expanded ? '收起筛选' : '展开筛选',
            ),
          ],
        ),
        if (activeSite == null)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text('请先选择数据源', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            ),
          ),
        if (activeSite != null && _expanded)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 类型筛选（从API动态获取）
                  typeListAsync.when(
                    data: (types) {
                      if (types.isEmpty) return const SizedBox.shrink();
                      final allTypes = [
                        {'id': 0, 'name': '全部'},
                        ...types.map((t) => {'id': t.id, 'name': t.name}),
                      ];
                      return _buildTypeFilterRow('类型', allTypes);
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('加载分类...', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  // 地区筛选（从API动态获取）
                  areaListAsync.when(
                    data: (areas) {
                      if (areas.isEmpty) return const SizedBox.shrink();
                      final allAreas = ['全部', ...areas.map((a) => a.name)];
                      return _buildFilterRow('地区', allAreas, _selectedArea,
                          (v) => setState(() { _selectedArea = v; _currentPage = 1; _lastPageEmpty = false; }));
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('加载地区...', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterRow('年份', _years, _selectedYear,
                      (v) => setState(() { _selectedYear = v; _currentPage = 1; _lastPageEmpty = false; })),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        if (activeSite != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  Text(
                    _buildFilterSummary(),
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const Spacer(),
                  if (_selectedTypeId != 0 || _selectedArea != '全部' || _selectedYear != '全部')
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedTypeId = 0;
                        _selectedArea = '全部';
                        _selectedYear = '全部';
                        _currentPage = 1;
                        _lastPageEmpty = false;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close, size: 12, color: AppTheme.accentColor),
                            SizedBox(width: 2),
                            Text('清除', style: TextStyle(fontSize: 11, color: AppTheme.accentColor)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (activeSite != null)
          animeListAsync.when(
            data: (animes) {
              if (animes.isEmpty) {
                if (_currentPage > 1 && !_lastPageEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _lastPageEmpty = true);
                  });
                }
                if (_currentPage == 1) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 48, color: AppTheme.textSecondary),
                            SizedBox(height: 12),
                            Text('暂无结果', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              } else {
                if (_lastPageEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _lastPageEmpty = false);
                  });
                }
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: getCrossAxisCount(context),
                    childAspectRatio: 0.55,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => AnimeCard(anime: animes[index], showStatus: true, showRating: true, showYear: true),
                    childCount: animes.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.accentColor, size: 48),
                      const SizedBox(height: 12),
                      Text('加载失败: $e', style: const TextStyle(color: AppTheme.textSecondary)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(categoryAnimeProvider),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (activeSite != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
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
          ),
      ],
    );
  }

  Widget _buildTypeFilterRow(String label, List<Map<String, dynamic>> types) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: types.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final type = types[index];
              final isSelected = type['id'] == _selectedTypeId;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedTypeId = type['id'] as int;
                  _currentPage = 1;
                  _lastPageEmpty = false;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    type['name'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow(String label, List<String> items, String selected, ValueChanged<String> onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = item == selected;
              return GestureDetector(
                onTap: () => onTap(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _buildFilterSummary() {
    final parts = <String>[];
    if (_selectedTypeId != 0) {
      final typeList = ref.read(typeListProvider).valueOrNull;
      final typeName = typeList?.where((t) => t.id == _selectedTypeId).firstOrNull?.name;
      if (typeName != null) parts.add(typeName);
    }
    if (_selectedArea != '全部') parts.add(_selectedArea);
    if (_selectedYear != '全部') parts.add(_selectedYear);
    if (parts.isEmpty) return '全部动漫';
    return parts.join(' · ');
  }

}

