import 'dart:io';
import '../models/song_model.dart';

class MediaQueryService {

  Future<List<SongModel>> getSongsSafe() async {
    try {
      List<SongModel> songs = [];

      // 🔥 ONLINE DEMO
      songs.addAll([
        SongModel(
          id: 1,
          title: "SoundHelix 1",
          artist: "Online",
          data: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
          duration: null,
          albumId: null,
        ),
        SongModel(
          id: 2,
          title: "SoundHelix 2",
          artist: "Online",
          data: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
          duration: null,
          albumId: null,
        ),
      ]);

      // 🔥 OFFLINE (đa nền tảng)
      Directory? dir;

      if (Platform.isAndroid) {
        dir = Directory("/storage/emulated/0/Music");
      } else if (Platform.isWindows) {
        dir = Directory("C:/Users/Public/Music");
      }

      if (dir != null && dir.existsSync()) {
        final files = dir.listSync(recursive: true);

        int id = 100;

        for (var file in files) {
          if (file is File && file.path.toLowerCase().endsWith(".mp3")) {
            songs.add(
              SongModel(
                id: id++,
                title: file.path.split(Platform.pathSeparator).last,
                artist: "Offline",
                data: file.path,
                duration: null,
                albumId: null,
              ),
            );
          }
        }
      }

      return songs;
    } catch (e) {
      print("LOAD ERROR: $e");
      return [];
    }
  }

  Future<bool> requestPermission() async => true;
  Future<void> openSetting() async {}
}