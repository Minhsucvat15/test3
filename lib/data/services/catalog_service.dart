import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../models/song_model.dart';

class Catalog {
  final List<SongModel> songs;
  final List<CategoryModel> categories;
  final List<FeaturedItem> featured;
  final List<MixModel> mixes;
  final List<SuggestionModel> suggestions;
  final List<AlbumModel> albums;

  const Catalog({
    required this.songs,
    required this.categories,
    required this.featured,
    this.mixes = const [],
    this.suggestions = const [],
    this.albums = const [],
  });

  SongModel? songById(String id) {
    for (final s in songs) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<SongModel> songsByIds(List<String> ids) =>
      ids.map(songById).whereType<SongModel>().toList();

  Catalog copyWith({List<SongModel>? songs}) => Catalog(
        songs: songs ?? this.songs,
        categories: categories,
        featured: featured,
        mixes: mixes,
        suggestions: suggestions,
        albums: albums,
      );
}

/// Đọc catalog từ assets/data/songs.json + thêm bài offline trong máy
/// + thử kéo từ API local nếu có (10.0.2.2 emulator).
class CatalogService {
  final String apiUrl = 'http://10.0.2.2:3001/songs';

  Future<Catalog> loadCatalog() async {
    final raw = await rootBundle.loadString('assets/data/songs.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;

    final songs = (data['songs'] as List? ?? [])
        .map((e) => SongModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final categories = (data['categories'] as List? ?? [])
        .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final featured = (data['featured'] as List? ?? [])
        .map((e) => FeaturedItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final mixes = (data['mixes'] as List? ?? [])
        .map((e) => MixModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final suggestions = (data['suggestions'] as List? ?? [])
        .map((e) =>
            SuggestionModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final albums = (data['albums'] as List? ?? [])
        .map((e) => AlbumModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final extra = <SongModel>[];

    // 1) thử API local (dev server riêng)
    try {
      final res =
          await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        for (final item in list) {
          extra.add(
            SongModel.fromJson(Map<String, dynamic>.from(item as Map)),
          );
        }
      }
    } catch (_) {/* offline */}

    // 2) bài hát offline trong máy (Android Music dir / Windows Public Music)
    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Music');
      } else if (Platform.isWindows) {
        dir = Directory('C:/Users/Public/Music');
      }
      if (dir != null && dir.existsSync()) {
        var idx = 0;
        for (final f in dir.listSync(recursive: true)) {
          if (f is File && f.path.toLowerCase().endsWith('.mp3')) {
            extra.add(
              SongModel(
                id: 'local_${idx++}',
                title: f.path.split(Platform.pathSeparator).last,
                artist: 'Trên máy',
                data: f.path,
                category: 'local',
              ),
            );
          }
        }
      }
    } catch (_) {}

    return Catalog(
      songs: [...songs, ...extra],
      categories: categories,
      featured: featured,
      mixes: mixes,
      suggestions: suggestions,
      albums: albums,
    );
  }
}
