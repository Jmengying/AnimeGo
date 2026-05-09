import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/anime.dart';
import '../../providers/auth_provider.dart';
import '../../providers/history_provider.dart';
import '../../utils/responsive.dart';
import '../detail/anime_detail_screen.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final email = user['email'] ?? '';
    final favs = await ref.read(storageServiceProvider).getFavorites(email);
    if (mounted) setState(() { _favorites = favs; _isLoading = false; });
  }

  Future<void> _removeFavorite(int index) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final email = user['email'] ?? '';
    await ref.read(storageServiceProvider).toggleFavorite(email, _favorites[index]);
    if (mounted) {
      setState(() => _favorites.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已取消收藏'), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的收藏')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _favorites.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: AppTheme.textSecondary),
                      SizedBox(height: 16),
                      Text('还没有收藏的动漫', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: getCrossAxisCount(context),
                    childAspectRatio: 0.55,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final anime = Anime.fromJson(_favorites[index]);
                    return _FavoriteAnimeCard(
                      anime: anime,
                      onRemove: () => _removeFavorite(index),
                    );
                  },
                ),
    );
  }

}

class _FavoriteAnimeCard extends StatelessWidget {
  final Anime anime;
  final VoidCallback onRemove;

  const _FavoriteAnimeCard({required this.anime, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnimeDetailScreen(anime: anime))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppTheme.cardColor),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: anime.cover,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppTheme.cardColor),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.cardColor,
                      child: const Center(child: Icon(Icons.broken_image, color: AppTheme.textSecondary)),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite, color: AppTheme.accentColor, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(anime.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
