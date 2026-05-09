import 'source_site.dart';
import 'source_warehouse.dart';

class SourceSubscription {
  final String id;
  final String name;
  final String url;
  final List<SourceWarehouse> warehouses;
  final bool isBuiltIn;

  SourceSubscription({
    required this.id,
    required this.name,
    required this.url,
    this.warehouses = const [],
    this.isBuiltIn = false,
  });

  List<SourceSite> get allMaccmsSites =>
      warehouses.expand((w) => w.maccmsSites).toList();
  int get warehouseCount => warehouses.length;
  int get siteCount => warehouses.fold(0, (sum, w) => sum + w.sites.length);
  int get maccmsSiteCount =>
      warehouses.fold(0, (sum, w) => sum + w.maccmsCount);

  factory SourceSubscription.fromJson(Map<String, dynamic> json) {
    return SourceSubscription(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      warehouses: (json['warehouses'] as List<dynamic>?)
              ?.map((e) => SourceWarehouse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isBuiltIn: json['isBuiltIn'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'warehouses': warehouses.map((w) => w.toJson()).toList(),
      'isBuiltIn': isBuiltIn,
    };
  }
}
