import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/source_site.dart';
import '../models/source_warehouse.dart';
import '../models/source_subscription.dart';
import '../services/source_service.dart';

final sourceServiceProvider = Provider<SourceService>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

// 版本计数器，切换源时自增以触发所有依赖provider刷新
final sourceVersionProvider = StateProvider<int>((ref) => 0);

final subscriptionsProvider = Provider<List<SourceSubscription>>((ref) {
  ref.watch(sourceVersionProvider);
  return ref.watch(sourceServiceProvider).subscriptions;
});

final activeSubscriptionProvider = Provider<SourceSubscription?>((ref) {
  ref.watch(sourceVersionProvider);
  return ref.watch(sourceServiceProvider).activeSubscription;
});

final activeWarehousesProvider = Provider<List<SourceWarehouse>>((ref) {
  ref.watch(sourceVersionProvider);
  final sub = ref.watch(sourceServiceProvider).activeSubscription;
  return sub?.warehouses ?? [];
});

final activeWarehouseProvider = Provider<SourceWarehouse?>((ref) {
  ref.watch(sourceVersionProvider);
  return ref.watch(sourceServiceProvider).activeWarehouse;
});

final activeWarehouseSitesProvider = Provider<List<SourceSite>>((ref) {
  ref.watch(sourceVersionProvider);
  return ref.watch(sourceServiceProvider).currentWarehouseSites;
});

final activeSiteProvider = Provider<SourceSite?>((ref) {
  ref.watch(sourceVersionProvider);
  return ref.watch(sourceServiceProvider).activeSite;
});

final activeApiUrlProvider = Provider<String>((ref) {
  ref.watch(sourceVersionProvider);
  final site = ref.watch(sourceServiceProvider).activeSite;
  return site?.apiUrl ?? '';
});
