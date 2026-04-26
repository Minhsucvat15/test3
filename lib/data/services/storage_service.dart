import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Lưu / đọc các file JSON trong thư mục riêng của app.
/// Dùng cho user list, playlists, recents, favorites...
class StorageService {
  Future<File> _file(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/goodmusic');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return File('${folder.path}/$name');
  }

  Future<dynamic> readJson(String name, {dynamic fallback}) async {
    try {
      final f = await _file(name);
      if (!await f.exists()) return fallback;
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return fallback;
      return jsonDecode(raw);
    } catch (_) {
      return fallback;
    }
  }

  Future<void> writeJson(String name, dynamic data) async {
    final f = await _file(name);
    await f.writeAsString(jsonEncode(data));
  }

  Future<void> delete(String name) async {
    final f = await _file(name);
    if (await f.exists()) await f.delete();
  }
}
