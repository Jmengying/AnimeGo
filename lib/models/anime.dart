class Anime {
  final String id;
  final String title;
  final String cover;
  final String description;
  final String type;
  final String year;
  final String status;
  final String? rating;
  final List<String> genres;
  final String? updateInfo;
  final List<Episode>? episodes;
  final List<EpisodeSource> episodeSources;

  Anime({
    required this.id,
    required this.title,
    required this.cover,
    this.description = '',
    this.type = '',
    this.year = '',
    this.status = '',
    this.rating,
    this.genres = const [],
    this.updateInfo,
    this.episodes,
    this.episodeSources = const [],
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      cover: json['cover']?.toString() ?? json['img']?.toString() ?? json['pic']?.toString() ?? '',
      description: json['description']?.toString() ?? json['intro']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      status: json['status']?.toString() ?? json['state']?.toString() ?? '',
      rating: json['rating']?.toString() ?? json['score']?.toString(),
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      updateInfo: json['updateInfo']?.toString() ?? json['newest']?.toString(),
      episodes: (json['episodes'] as List<dynamic>?)?.map((e) => Episode.fromJson(e as Map<String, dynamic>)).toList(),
      episodeSources: (json['episodeSources'] as List<dynamic>?)?.map((e) => EpisodeSource.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cover': cover,
      'description': description,
      'type': type,
      'year': year,
      'status': status,
      'rating': rating,
      'genres': genres,
      'updateInfo': updateInfo,
      if (episodes != null) 'episodes': episodes!.map((e) => e.toJson()).toList(),
      if (episodeSources.isNotEmpty) 'episodeSources': episodeSources.map((s) => s.toJson()).toList(),
    };
  }
}

class EpisodeSource {
  final String name;
  final List<Episode> episodes;

  EpisodeSource({required this.name, required this.episodes});

  factory EpisodeSource.fromJson(Map<String, dynamic> json) {
    return EpisodeSource(
      name: json['name']?.toString() ?? '',
      episodes: (json['episodes'] as List<dynamic>?)?.map((e) => Episode.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'episodes': episodes.map((e) => e.toJson()).toList(),
    };
  }
}

class Episode {
  final String title;
  final String url;

  Episode({
    required this.title,
    required this.url,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
    };
  }
}
