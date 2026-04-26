import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../services/storage_service.dart';

/// Quản lý dữ liệu library theo user (favorites, recent, playlists).
/// Lưu vào file lib_<userId>.json để mỗi user có dữ liệu riêng.
class LibraryRepository extends ChangeNotifier {
  LibraryRepository(this._storage);

  final StorageService _storage;

  String? _userId;
  List<String> _favoriteIds = [];
  List<String> _recentIds = [];
  List<PlaylistModel> _playlists = [];

  List<String> get favoriteIds => List.unmodifiable(_favoriteIds);
  List<String> get recentIds => List.unmodifiable(_recentIds);
  List<PlaylistModel> get playlists => List.unmodifiable(_playlists);

  String _file(String uid) => 'lib_$uid.json';

  Future<void> bind(String? userId) async {
    _userId = userId;
    if (userId == null) {
      _favoriteIds = [];
      _recentIds = [];
      _playlists = [];
      notifyListeners();
      return;
    }
    final raw = await _storage.readJson(_file(userId), fallback: {});
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    _favoriteIds = (map['favorites'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    _recentIds = (map['recents'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    _playlists = (map['playlists'] as List? ?? [])
        .map((e) => PlaylistModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    notifyListeners();
  }

  Future<void> _save() async {
    final uid = _userId;
    if (uid == null) return;
    await _storage.writeJson(_file(uid), {
      'favorites': _favoriteIds,
      'recents': _recentIds,
      'playlists': _playlists.map((e) => e.toJson()).toList(),
    });
  }

  // Favorites
  bool isFavorite(String songId) => _favoriteIds.contains(songId);

  Future<void> toggleFavorite(SongModel song) async {
    if (_favoriteIds.contains(song.id)) {
      _favoriteIds.remove(song.id);
    } else {
      _favoriteIds.insert(0, song.id);
    }
    notifyListeners();
    await _save();
  }

  // Recents
  Future<void> pushRecent(SongModel song) async {
    _recentIds.remove(song.id);
    _recentIds.insert(0, song.id);
    if (_recentIds.length > 30) _recentIds = _recentIds.sublist(0, 30);
    notifyListeners();
    await _save();
  }

  Future<void> clearRecent() async {
    _recentIds.clear();
    notifyListeners();
    await _save();
  }

  // Playlists CRUD
  Future<PlaylistModel> createPlaylist({
    required String name,
    String? description,
    int colorValue = 0xFF1ED760,
  }) async {
    final p = PlaylistModel(
      id: const Uuid().v4(),
      name: name,
      description: description,
      songIds: const [],
      createdAt: DateTime.now(),
      colorValue: colorValue,
    );
    _playlists.insert(0, p);
    notifyListeners();
    await _save();
    return p;
  }

  Future<void> updatePlaylist(
    String id, {
    String? name,
    String? description,
    int? colorValue,
  }) async {
    final idx = _playlists.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _playlists[idx] = _playlists[idx].copyWith(
      name: name,
      description: description,
      colorValue: colorValue,
    );
    notifyListeners();
    await _save();
  }

  Future<void> deletePlaylist(String id) async {
    _playlists.removeWhere((p) => p.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;
    final p = _playlists[idx];
    if (p.songIds.contains(songId)) return;
    _playlists[idx] = p.copyWith(songIds: [...p.songIds, songId]);
    notifyListeners();
    await _save();
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;
    final p = _playlists[idx];
    _playlists[idx] = p.copyWith(
      songIds: p.songIds.where((s) => s != songId).toList(),
    );
    notifyListeners();
    await _save();
  }
}
