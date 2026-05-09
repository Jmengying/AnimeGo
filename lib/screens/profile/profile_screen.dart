import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/history_provider.dart';
import '../auth/login_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'source_manage_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final historyAsync = ref.watch(watchHistoryProvider);
    final favoritesAsync = ref.watch(favoritesProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('我的'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => _showLogoutDialog(context, ref),
            ),
          ],
        ),
        // User info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    (user?['username'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?['username'] ?? '用户',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?['email'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Stats
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('观看记录', historyAsync.valueOrNull?.length ?? 0, Icons.history_rounded),
                  _buildStat('收藏', favoritesAsync.valueOrNull?.length ?? 0, Icons.favorite_rounded),
                ],
              ),
            ),
          ),
        ),
        // Menu items
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMenuItem(
                  Icons.cloud_outlined,
                  '数据源管理',
                  '添加或切换视频数据源',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SourceManageScreen()),
                  ),
                ),
                _buildMenuItem(
                  Icons.history_rounded,
                  '观看记录',
                  '查看你的观看历史',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                ),
                _buildMenuItem(
                  Icons.favorite_border_rounded,
                  '我的收藏',
                  '收藏的动漫',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                  ),
                ),
                _buildMenuItem(
                  Icons.info_outline_rounded,
                  '关于',
                  'AnimeGo v1.0.0',
                  () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'AnimeGo',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(Icons.play_circle_fill, color: AppTheme.primaryColor, size: 48),
                      children: const [
                        Text('一个简洁的动漫观看应用\n支持自定义 maccms 数据源'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('退出登录', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('确定要退出登录吗？', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              ref.invalidate(currentUserProvider);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}
