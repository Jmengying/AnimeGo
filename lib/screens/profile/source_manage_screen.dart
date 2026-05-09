import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/source_subscription.dart';
import '../../models/source_warehouse.dart';
import '../../models/source_site.dart';
import '../../services/source_service.dart';
import '../../providers/source_provider.dart';

class SourceManageScreen extends ConsumerStatefulWidget {
  const SourceManageScreen({super.key});

  @override
  ConsumerState<SourceManageScreen> createState() => _SourceManageScreenState();
}

class _SourceManageScreenState extends ConsumerState<SourceManageScreen> {
  @override
  Widget build(BuildContext context) {
    final subscriptions = ref.watch(subscriptionsProvider);
    final activeSite = ref.watch(activeSiteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据源管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: '导入订阅',
            onPressed: () => _showSubscriptionDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新全部',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('正在刷新所有订阅...'), duration: Duration(seconds: 2)),
              );
              for (final sub in subscriptions) {
                await ref.read(sourceServiceProvider).refreshSubscription(sub.id);
              }
              ref.read(sourceVersionProvider.notifier).state++;
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('刷新完成'), backgroundColor: Colors.green),
                );
              }
            },
          ),
        ],
      ),
      body: subscriptions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: AppTheme.textSecondary),
                  SizedBox(height: 16),
                  Text('暂无数据源', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('点击右上角导入订阅', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: subscriptions.length,
              itemBuilder: (context, index) => _buildSubscriptionTile(subscriptions[index], activeSite),
            ),
    );
  }

  Widget _buildSubscriptionTile(SourceSubscription sub, SourceSite? activeSite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(left: 8),
        title: Row(
          children: [
            Icon(
              sub.isBuiltIn ? Icons.cloud_outlined : Icons.link,
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
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (sub.isBuiltIn)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('内置', style: TextStyle(fontSize: 10, color: AppTheme.primaryColor)),
              ),
          ],
        ),
        subtitle: Text(
          '${sub.warehouseCount}个仓库 · ${sub.maccmsSiteCount}个可用源',
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 20),
          onSelected: (v) => _handleSubAction(v, sub),
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'refresh', child: Text('刷新')),
            if (!sub.isBuiltIn)
              const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
          ],
        ),
        children: sub.warehouses.map((wh) => _buildWarehouseTile(sub, wh, activeSite)).toList(),
      ),
    );
  }

  Widget _buildWarehouseTile(SourceSubscription sub, SourceWarehouse wh, SourceSite? activeSite) {
    final maccmsSites = wh.maccmsSites;
    if (maccmsSites.isEmpty) return const SizedBox.shrink();

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 24),
      childrenPadding: const EdgeInsets.only(left: 16),
      title: Text(
        wh.name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
      ),
      subtitle: Text(
        '${maccmsSites.length}个可用源',
        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
      ),
      children: maccmsSites.map((site) => _buildSiteTile(sub, wh, site, activeSite)).toList(),
    );
  }

  Widget _buildSiteTile(SourceSubscription sub, SourceWarehouse wh, SourceSite site, SourceSite? activeSite) {
    final isActive = activeSite?.id == site.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryColor.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border.all(color: AppTheme.primaryColor, width: 1) : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Icon(
          isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          size: 18,
          color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                site.name,
                style: TextStyle(
                  fontSize: 13,
                  color: isActive ? AppTheme.primaryColor : AppTheme.textPrimary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('当前', style: TextStyle(fontSize: 9, color: AppTheme.primaryColor)),
              ),
          ],
        ),
        subtitle: Text(
          site.apiUrl,
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.wifi_find, size: 16),
              tooltip: '测试',
              color: AppTheme.textSecondary,
              onPressed: () => _testSite(site),
            ),
            if (!isActive)
              IconButton(
                icon: const Icon(Icons.play_arrow, size: 16),
                tooltip: '使用',
                color: AppTheme.primaryColor,
                onPressed: () => _activateSite(sub, wh, site),
              ),
          ],
        ),
        onTap: isActive ? null : () => _activateSite(sub, wh, site),
      ),
    );
  }

  void _activateSite(SourceSubscription sub, SourceWarehouse wh, SourceSite site) {
    final service = ref.read(sourceServiceProvider);
    service.setActiveSite(sub.id, wh.id, site.id);
    ref.read(sourceVersionProvider.notifier).state++;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已切换到: ${wh.name} - ${site.name}'), duration: const Duration(seconds: 1)),
    );
  }

  void _testSite(SourceSite site) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在测试: ${site.name}...'), duration: const Duration(seconds: 2)),
    );
    final ok = await ref.read(sourceServiceProvider).testSource(site.apiUrl);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '${site.name}: 连接成功!' : '${site.name}: 连接失败'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _handleSubAction(String action, SourceSubscription sub) async {
    switch (action) {
      case 'refresh':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('正在刷新 ${sub.name}...'), duration: const Duration(seconds: 3)),
        );
        await ref.read(sourceServiceProvider).refreshSubscription(sub.id);
        ref.read(sourceVersionProvider.notifier).state++;
        break;
      case 'delete':
        _deleteSubscription(sub);
        break;
    }
  }

  void _deleteSubscription(SourceSubscription sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除订阅 "${sub.name}" 及其所有源吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              ref.read(sourceServiceProvider).removeSubscription(sub.id);
              ref.read(sourceVersionProvider.notifier).state++;
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(BuildContext context) {
    final customUrlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入订阅源'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('内置订阅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                ...SourceService.builtinSubscriptions.map((sub) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cloud_download, color: AppTheme.primaryColor, size: 20),
                  title: Text(sub['name']!, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                    sub['url']!,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _importSubscription(sub['url']!, sub['name']!);
                  },
                )),
                const Divider(height: 24),
                const Text('自定义订阅URL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                TextField(
                  controller: customUrlCtrl,
                  decoration: const InputDecoration(
                    hintText: 'http://xxx.com/dc',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                const Text(
                  '支持TVBox/影视仓格式的订阅链接（多仓/单仓）',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final url = customUrlCtrl.text.trim();
              if (url.isEmpty) return;
              Navigator.pop(ctx);
              _importSubscription(url, '自定义');
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  Future<void> _importSubscription(String url, String name) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在导入 $name 订阅...'), duration: const Duration(seconds: 5)),
    );

    try {
      final sub = await ref.read(sourceServiceProvider).importSubscription(url, name: name);
      if (!mounted) return;

      if (sub.warehouses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未找到可用的数据源'), backgroundColor: Colors.orange),
        );
        return;
      }

      await ref.read(sourceServiceProvider).addSubscription(sub);
      ref.read(sourceVersionProvider.notifier).state++;

      final siteCount = sub.maccmsSiteCount;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成功导入 ${sub.warehouseCount} 个仓库, $siteCount 个源'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
