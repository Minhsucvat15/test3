class SongModel {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? data; // local path / remote URL of audio
  final String? cover; // image URL
  final String? category;
  final int? colorValue; // 0xAARRGGBB
  final int? duration;
  final int playCount;

  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.data,
    this.cover,
    this.category,
    this.colorValue,
    this.duration,
    this.playCount = 0,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    final colorRaw = json['color'];
    int? color;
    if (colorRaw is int) color = colorRaw;
    if (colorRaw is String) color = int.tryParse(colorRaw);

    return SongModel(
      id: (json['id'] ?? '').toString(),
      title: json['title']?.toString() ?? 'Untitled',
      artist: json['artist']?.toString() ?? 'Unknown',
      album: json['album']?.toString(),
      data: (json['url'] ?? json['data'])?.toString(),
      cover: json['cover']?.toString(),
      category: json['category']?.toString(),
      colorValue: color,
      duration: json['duration'] is int ? json['duration'] as int : null,
      playCount: json['playCount'] is int ? json['playCount'] as int : 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'url': data,
        'cover': cover,
        'category': category,
        'color': colorValue,
        'duration': duration,
        'playCount': playCount,
      };

  SongModel copyWith({String? data}) => SongModel(
        id: id,
        title: title,
        artist: artist,
        album: album,
        data: data ?? this.data,
        cover: cover,
        category: category,
        colorValue: colorValue,
        duration: duration,
        playCount: playCount,
      );
}

class CategoryModel {
  final String id;
  final String name;
  final int colorValue;
  const CategoryModel({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
        id: j['id'].toString(),
        name: j['name'].toString(),
        colorValue: int.parse(j['color'].toString()),
      );
}

class FeaturedItem {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final String? category;

  const FeaturedItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    this.category,
  });

  factory FeaturedItem.fromJson(Map<String, dynamic> j) => FeaturedItem(
        id: j['id'].toString(),
        title: j['title'].toString(),
        subtitle: j['subtitle'].toString(),
        image: j['image'].toString(),
        category: j['category']?.toString(),
      );
}

class MixModel {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final int colorValue;
  final List<String> songIds;

  const MixModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.colorValue,
    required this.songIds,
  });

  factory MixModel.fromJson(Map<String, dynamic> j) => MixModel(
        id: j['id'].toString(),
        title: j['title'].toString(),
        subtitle: (j['subtitle'] ?? '').toString(),
        image: j['image'].toString(),
        colorValue: int.tryParse(j['color']?.toString() ?? '') ?? 0xFF1ED760,
        songIds: (j['songIds'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

class SuggestionModel {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final int colorValue;
  final List<String> songIds;

  const SuggestionModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.colorValue,
    required this.songIds,
  });

  factory SuggestionModel.fromJson(Map<String, dynamic> j) => SuggestionModel(
        id: j['id'].toString(),
        title: j['title'].toString(),
        subtitle: (j['subtitle'] ?? '').toString(),
        image: j['image'].toString(),
        colorValue: int.tryParse(j['color']?.toString() ?? '') ?? 0xFF1ED760,
        songIds: (j['songIds'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

class AlbumModel {
  final String id;
  final String title;
  final String artist;
  final int? year;
  final String cover;
  final int colorValue;
  final List<String> songIds;

  const AlbumModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.cover,
    required this.colorValue,
    required this.songIds,
    this.year,
  });

  factory AlbumModel.fromJson(Map<String, dynamic> j) => AlbumModel(
        id: j['id'].toString(),
        title: j['title'].toString(),
        artist: j['artist'].toString(),
        year: j['year'] is int ? j['year'] as int : null,
        cover: j['cover'].toString(),
        colorValue: int.tryParse(j['color']?.toString() ?? '') ?? 0xFF1ED760,
        songIds: (j['songIds'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
