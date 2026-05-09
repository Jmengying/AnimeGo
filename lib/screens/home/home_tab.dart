import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../providers/anime_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/source_provider.dart';
import '../../models/anime.dart';
import '../../models/source_subscription.dart';
import '../../models/watch_record.dart';
import '../../utils/responsive.dart';
import '../../widgets/anime_card.dart';
import '../detail/anime_detail_screen.dart';
import '../player/player_screen.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  @override
  Widget build(BuildContext context) {
    final recommendAsync = ref.watch(recommendAnimeProvider);
    final latestAsync = ref.watch(latestAnimeProvider);
    final activeSite = ref.watch(activeSiteProvider);
    final historyAsync = ref.watch(watchHistoryProvider);

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {
        ref.invalidate(recommendAnimeProvider);
        ref.invalidate(latestAnimeProvider);
        ref.invalidate(watchHistoryProvider);
        // Wait for at least one provider to complete
        await ref.read(recommendAnimeProvider.future);
      },
      child: CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: _buildSourceSelector(context, ref),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '刷新',
              onPressed: () => ref.read(sourceVersionProvider.notifier).state++,
            ),
          ],
        ),
        // 正在加载数据源提示
        if (activeSite == null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  const CircularProgressIndicator(color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  const Text(
                    '暂无可用数据源',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '请在"我的"→"数据源管理"中导入订阅',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        // Banner / Carousel
        if (activeSite != null)
          SliverToBoxAdapter(
            child: recommendAsync.when(
              data: (animes) => _buildBanner(context, animes.take(5).toList()),
              loading: () => _buildBannerSkeleton(),
              error: (_, __) => const SizedBox(height: 200),
            ),
          ),
        // Continue Watching section
        if (activeSite != null)
          ..._buildContinueWatching(context, historyAsync),
        // Latest section
        if (activeSite != null) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '最近更新',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          latestAsync.when(
            data: (animes) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: getCrossAxisCount(context),
                  childAspectRatio: 0.55,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => AnimeCard(anime: animes[index], showStatus: true, showUpdateInfo: true),
                  childCount: animes.length,
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('加载失败: $e',
                      style: const TextStyle(color: AppTheme.textSecondary)),
                ),
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    ),
    );
  }

  Widget _buildSourceSelector(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(subscriptionsProvider);
    final activeWh = ref.watch(activeWarehouseProvider);
    final activeSite = ref.watch(activeSiteProvider);

    final displayText = activeSite != null
        ? '${activeWh?.name ?? ''} - ${activeSite.name}'
        : '选择数据源';

    return GestureDetector(
      onTap: () => _showSourcePicker(context, ref, subscriptions),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.play_circle_fill, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              displayText,
              style: const TextStyle(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 20),
        ],
      ),
    );
  }

  void _showSourcePicker(
      BuildContext context, WidgetRef ref, List<SourceSubscription> subs) {
    final activeWh = ref.read(activeWarehouseProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '选择数据源',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: subs.length,
                itemBuilder: (ctx, index) {
                  final sub = subs[index];
                  final maccmsSites = sub.allMaccmsSites;
                  return ExpansionTile(
                    title: Row(
                      children: [
                        Icon(
                          sub.isBuiltIn
                              ? Icons.cloud_outlined
                              : Icons.link,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sub.name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${maccmsSites.length}源',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                    children: sub.warehouses.map((wh) {
                      final sites = wh.maccmsSites;
                      if (sites.isEmpty) return const SizedBox.shrink();
                      return ExpansionTile(
                        title: Text(
                          wh.name,
                          style: const TextStyle(
                              fontSize: 14, color: AppTheme.textPrimary),
                        ),
                        subtitle: Text(
                          '${sites.length}个可用源',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        children: sites.map((site) {
                          final isActive = activeWh?.id == wh.id &&
                              ref.read(activeSiteProvider)?.id == site.id;
                          return ListTile(
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 32),
                            leading: Icon(
                              isActive
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 18,
                              color: isActive
                                  ? AppTheme.primaryColor
                                  : AppTheme.textSecondary,
                            ),
                            title: Text(
                              site.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: isActive
                                    ? AppTheme.primaryColor
                                    : AppTheme.textPrimary,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            onTap: () {
                              final service =
                                  ref.read(sourceServiceProvider);
                              service.setActiveSite(sub.id, wh.id, site.id);
                              ref.read(sourceVersionProvider.notifier).state++;
                              Navigator.pop(ctx);
                            },
                          );
                        }).toList(),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context, List<Anime> animes) {
    if (animes.isEmpty) return const SizedBox(height: 200);
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: animes.length,
        controller: PageController(viewportFraction: 0.9),
        itemBuilder: (context, index) {
          final anime = animes[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AnimeDetailScreen(anime: anime)),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppTheme.cardColor,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: anime.cover,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppTheme.cardColor),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.cardColor,
                      child: const Icon(Icons.broken_image,
                          color: AppTheme.textSecondary),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8)
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anime.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (anime.updateInfo != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            anime.updateInfo!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBannerSkeleton() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  List<Widget> _buildContinueWatching(BuildContext context, AsyncValue<List<WatchRecord>> historyAsync) {
    final records = historyAsync.valueOrNull;
    if (records == null || records.isEmpty) return [];

    // Deduplicate by animeId, keep the most recent
    final seen = <String>{};
    final uniqueRecords = <WatchRecord>[];
    for (final r in records) {
      if (seen.add(r.animeId)) {
        uniqueRecords.add(r);
        if (uniqueRecords.length >= 10) break;
      }
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '继续观看',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: uniqueRecords.length,
            itemBuilder: (context, index) {
              final record = uniqueRecords[index];
              return _buildContinueWatchingCard(context, record);
            },
          ),
        ),
      ),
    ];
  }

  Widget _buildContinueWatchingCard(BuildContext context, WatchRecord record) {
    return GestureDetector(
      onTap: () {
        final anime = Anime(
          id: record.animeId,
          title: record.animeTitle,
          cover: record.animeCover,
        );
        final episode = Episode(title: record.episodeTitle, url: record.episodeUrl);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlayerScreen(anime: anime, episode: episode)),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Cover image
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: record.animeCover,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppTheme.cardColor),
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.cardColor,
                  child: const Icon(Icons.broken_image, color: AppTheme.textSecondary, size: 32),
                ),
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                  ),
                ),
              ),
            ),
            // Play icon
            const Positioned(
              top: 28,
              left: 0,
              right: 0,
              child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 36),
            ),
            // Info
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    record.animeTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '看到 ${record.episodeTitle}',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (record.duration > 0) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: record.progressPercent.clamp(0.0, 1.0),
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

