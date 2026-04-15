class SongModel {
  final int id;
  final String title;
  final String artist;
  final String? data;
  final int? duration;
  final int? albumId;

  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.data,
    required this.duration,
    required this.albumId,
  });
}