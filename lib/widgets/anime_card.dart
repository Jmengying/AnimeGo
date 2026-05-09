import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../models/anime.dart';
import '../screens/detail/anime_detail_screen.dart';

class AnimeCard extends StatelessWidget {
  final Anime anime;
  final bool showStatus;
  final bool showRating;
  final bool showUpdateInfo;
  final bool showYear;

  const AnimeCard({
    super.key,
    required this.anime,
    this.showStatus = false,
    this.showRating = false,
    this.showUpdateInfo = false,
    this.showYear = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AnimeDetailScreen(anime: anime)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.cardColor,
              ),
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
                      child: const Center(
                        child: Icon(Icons.broken_image, color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  if (showStatus && anime.status.isNotEmpty)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: anime.status == '连载中'
                              ? AppTheme.primaryColor
                              : AppTheme.accentColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          anime.status,
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                  if (showRating && anime.rating != null && anime.rating!.isNotEmpty)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 11),
                            const SizedBox(width: 2),
                            Text(anime.rating!, style: const TextStyle(fontSize: 10, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            anime.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (showUpdateInfo && anime.updateInfo != null)
            Text(
              anime.updateInfo!,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (showYear && anime.year.isNotEmpty)
            Text(
              anime.year,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
        ],
      ),
    );
  }
}
