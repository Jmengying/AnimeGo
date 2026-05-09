class SourceSite {
  final String id;
  final String name;
  final String apiUrl;
  final int type; // TVBox type: 1=maccms, 3=spider, 4=jsapi, 0=xml
  final String? ext; // 扩展配置URL
  bool isActive;

  SourceSite({
    required this.id,
    required this.name,
    required this.apiUrl,
    this.type = 1,
    this.ext,
    this.isActive = true,
  });

  bool get isMaccms => type == 1 && apiUrl.contains('api.php');
  bool get isPlayable => isMaccms;

  factory SourceSite.fromJson(Map<String, dynamic> json) {
    return SourceSite(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      apiUrl: json['apiUrl'] ?? '',
      type: json['type'] ?? 1,
      ext: json['ext'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'apiUrl': apiUrl,
      'type': type,
      'ext': ext,
      'isActive': isActive,
    };
  }
}
