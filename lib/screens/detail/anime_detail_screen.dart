import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/anime.dart';
import '../../providers/anime_provider.dart';
import '../../providers/source_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/history_provider.dart';
import '../player/player_screen.dart';

class AnimeDetailScreen extends ConsumerStatefulWidget {
  final Anime anime;
  const AnimeDetailScreen({super.key, required this.anime});

  @override
  ConsumerState<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends ConsumerState<AnimeDetailScreen> {
  bool _isFavorite = false;
  int _selectedSourceIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final email = user['email'] ?? '';
    final isFav = await ref.read(storageServiceProvider).isFavorite(email, widget.anime.id);
    if (mounted) setState(() => _isFavorite = isFav);
  }

  Future<void> _toggleFavorite() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final email = user['email'] ?? '';
    await ref.read(storageServiceProvider).toggleFavorite(email, widget.anime.toJson());
    if (mounted) {
      setState(() => _isFavorite = !_isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? '已收藏' : '已取消收藏'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(animeDetailProvider(widget.anime.id));
    final anime = widget.anime;
    final activeWh = ref.watch(activeWarehouseProvider);
    final activeSite = ref.watch(activeSiteProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: anime.cover,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppTheme.cardColor),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.cardColor,
                      child: const Icon(Icons.broken_image, color: AppTheme.textSecondary),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.backgroundColor.withOpacity(0.8),
                          AppTheme.backgroundColor,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? AppTheme.accentColor : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
          ),
          // Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  // 数据来源
                  if (activeWh != null && activeSite != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.source, size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '来源: ${activeWh.name} - ${activeSite.name}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (anime.type.isNotEmpty) _buildTag(anime.type),
                      if (anime.year.isNotEmpty) _buildTag(anime.year),
                      if (anime.status.isNotEmpty) _buildTag(anime.status),
                      if (anime.rating != null && anime.rating!.isNotEmpty)
                        _buildTag('评分: ${anime.rating}'),
                      ...anime.genres.map((g) => _buildTag(g)),
                    ],
                  ),
                  if (anime.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '简介',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      anime.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Episodes
          detailAsync.when(
            data: (detail) {
              final sources = detail?.episodeSources ?? [];
              if (sources.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '选集',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Column(
                            children: [
                              Icon(Icons.videocam_off, size: 48, color: AppTheme.textSecondary),
                              SizedBox(height: 8),
                              Text('暂无可播放的剧集', style: TextStyle(color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              }
              if (_selectedSourceIndex >= sources.length) _selectedSourceIndex = 0;
              final currentSource = sources[_selectedSourceIndex];
              final episodes = currentSource.episodes;
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 源选择器
                      if (sources.length > 1) ...[
                        SizedBox(
                          height: 34,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: sources.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final isSelected = index == _selectedSourceIndex;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedSourceIndex = index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                                    borderRadius: BorderRadius.circular(17),
                                    border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    sources[index].name,
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
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          const Text(
                            '选集',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '共${episodes.length}集',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: episodes.asMap().entries.map((entry) {
                          return GestureDetector(
                            onTap: () => _playEpisode(context, anime, entry.value.title, entry.value.url, episodes: episodes),
                            child: Container(
                              width: 72,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.cardColor),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                entry.value.title,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('加载剧集失败', style: const TextStyle(color: AppTheme.textSecondary)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _playEpisode(BuildContext context, Anime anime, String epTitle, String epUrl, {List<Episode>? episodes}) {
    // Use anime with full episode list if available
    final animeWithEpisodes = (episodes != null && episodes.isNotEmpty)
        ? Anime(
            id: anime.id,
            title: anime.title,
            cover: anime.cover,
            description: anime.description,
            type: anime.type,
            year: anime.year,
            status: anime.status,
            rating: anime.rating,
            genres: anime.genres,
            updateInfo: anime.updateInfo,
            episodes: episodes,
          )
        : anime;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          anime: animeWithEpisodes,
          episode: Episode(title: epTitle, url: epUrl),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
    );
  }
}
