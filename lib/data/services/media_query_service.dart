import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/song_model.dart';

class MediaQueryService {
  // Android Emulator -> gọi máy thật qua 10.0.2.2
  final String apiUrl = "http://10.0.2.2:3001/songs";

  Future<List<SongModel>> getSongsSafe() async {
    try {
      List<SongModel> songs = [];

      // 1. LOAD ONLINE TỪ API THẬT
      try {
        final res = await http.get(Uri.parse(apiUrl));

        if (res.statusCode == 200) {
          final List data = jsonDecode(res.body);

          for (var item in data) {
            songs.add(
              SongModel(
                id: item['id'] ?? 0,
                title: item['title'] ?? 'No title',
                artist: item['artist'] ?? 'Unknown',
                data: item['url'],
                duration: null,
                albumId: null,
              ),
            );
          }
        } else {
          print("API STATUS ERROR: ${res.statusCode}");
        }
      } catch (e) {
        print("API ERROR: $e");
      }

      // 2. ONLINE DEMO CŨ
      songs.addAll([
        SongModel(
          id: 1001,
          title: "SoundHelix 1",
          artist: "Online",
          data: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
          duration: null,
          albumId: null,
        ),
        SongModel(
          id: 1002,
          title: "SoundHelix 2",
          artist: "Online",
          data: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
          duration: null,
          albumId: null,
        ),
      ]);

      // 3. OFFLINE GIỮ NGUYÊN
      Directory? dir;

      if (Platform.isAndroid) {
        dir = Directory("/storage/emulated/0/Music");
      } else if (Platform.isWindows) {
        dir = Directory("C:/Users/Public/Music");
      }

      if (dir != null && dir.existsSync()) {
        final files = dir.listSync(recursive: true);

        int id = 2000;

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