class WatchRecord {
  final String animeId;
  final String animeTitle;
  final String animeCover;
  final String episodeTitle;
  final String episodeUrl;
  final int progress;
  final int duration;
  final DateTime watchedAt;

  WatchRecord({
    required this.animeId,
    required this.animeTitle,
    required this.animeCover,
    required this.episodeTitle,
    required this.episodeUrl,
    this.progress = 0,
    this.duration = 0,
    required this.watchedAt,
  });

  factory WatchRecord.fromJson(Map<String, dynamic> json) {
    return WatchRecord(
      animeId: json['animeId'] ?? '',
      animeTitle: json['animeTitle'] ?? '',
      animeCover: json['animeCover'] ?? '',
      episodeTitle: json['episodeTitle'] ?? '',
      episodeUrl: json['episodeUrl'] ?? '',
      progress: json['progress'] ?? 0,
      duration: json['duration'] ?? 0,
      watchedAt: DateTime.tryParse(json['watchedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animeId': animeId,
      'animeTitle': animeTitle,
      'animeCover': animeCover,
      'episodeTitle': episodeTitle,
      'episodeUrl': episodeUrl,
      'progress': progress,
      'duration': duration,
      'watchedAt': watchedAt.toIso8601String(),
    };
  }

  double get progressPercent => duration > 0 ? progress / duration : 0;
}
