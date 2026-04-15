import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song_model.dart';
import 'audio_player_service.dart';

class MusicController {
  final AudioPlayerService audioService;

  List<SongModel> allSongs = [];
  List<SongModel> recentSongs = [];
  List<SongModel> favoriteSongs = [];

  MusicController(this.audioService);

  void setSongs(List<SongModel> songs) {
    allSongs = songs;
  }

  Future<void> playSongAt(int index) async {
    if (index < 0 || index >= allSongs.length) return;

    await audioService.playSongAt(allSongs, index);
    _addRecent(allSongs[index]);
  }

  Future<void> playSpecificSong(SongModel song) async {
    final index = allSongs.indexWhere((item) => item.id == song.id);

    if (index != -1) {
      await audioService.playSongAt(allSongs, index);
      _addRecent(song);
      return;
    }

    await audioService.playSong(song);
    _addRecent(song);
  }

  void _addRecent(SongModel song) {
    recentSongs.removeWhere((s) => s.id == song.id);
    recentSongs.insert(0, song);

    if (recentSongs.length > 20) {
      recentSongs.removeLast();
    }

    _save();
  }

  void toggleFavorite(SongModel song) {
    if (favoriteSongs.any((s) => s.id == song.id)) {
      favoriteSongs.removeWhere((s) => s.id == song.id);
    } else {
      favoriteSongs.add(song);
    }
    _save();
  }

  bool isFavorite(SongModel song) {
    return favoriteSongs.any((s) => s.id == song.id);
  }

  // 🔥 NEW
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    prefs.setString(
        "favorite", jsonEncode(favoriteSongs.map((e) => e.data).toList()));
    prefs.setString(
        "recent", jsonEncode(recentSongs.map((e) => e.data).toList()));
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final fav = jsonDecode(prefs.getString("favorite") ?? "[]");
    final rec = jsonDecode(prefs.getString("recent") ?? "[]");

    favoriteSongs = allSongs.where((s) => fav.contains(s.data)).toList();
    recentSongs = allSongs.where((s) => rec.contains(s.data)).toList();
  }
}