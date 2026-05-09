import 'source_site.dart';

class SourceWarehouse {
  final String id;
  final String name;
  final String url;
  final List<SourceSite> sites;

  SourceWarehouse({
    required this.id,
    required this.name,
    required this.url,
    this.sites = const [],
  });

  List<SourceSite> get maccmsSites => sites.where((s) => s.isMaccms).toList();
  int get maccmsCount => maccmsSites.length;

  factory SourceWarehouse.fromJson(Map<String, dynamic> json) {
    return SourceWarehouse(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      sites: (json['sites'] as List<dynamic>?)
              ?.map((e) => SourceSite.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'sites': sites.map((s) => s.toJson()).toList(),
    };
  }
}
