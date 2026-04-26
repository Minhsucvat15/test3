class PlaylistModel {
  final String id;
  final String name;
  final String? description;
  final List<String> songIds;
  final DateTime createdAt;
  final int colorValue;

  const PlaylistModel({
    required this.id,
    required this.name,
    required this.songIds,
    required this.createdAt,
    required this.colorValue,
    this.description,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> j) => PlaylistModel(
        id: j['id'].toString(),
        name: j['name'].toString(),
        description: j['description']?.toString(),
        songIds: (j['songIds'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        createdAt:
            DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
        colorValue: int.tryParse(j['color']?.toString() ?? '') ?? 0xFF1ED760,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'songIds': songIds,
        'createdAt': createdAt.toIso8601String(),
        'color': colorValue.toString(),
      };

  PlaylistModel copyWith({
    String? name,
    String? description,
    List<String>? songIds,
    int? colorValue,
  }) =>
      PlaylistModel(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        songIds: songIds ?? this.songIds,
        createdAt: createdAt,
        colorValue: colorValue ?? this.colorValue,
      );
}
