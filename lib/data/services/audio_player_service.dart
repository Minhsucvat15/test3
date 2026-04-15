import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';

enum RepeatMode { off, one, all }

class AudioPlayerService {
  final AudioPlayer player = AudioPlayer();

  final List<SongModel> _queue = [];
  int _currentIndex = -1;

  bool shuffle = false;
  RepeatMode repeatMode = RepeatMode.off;

  List<SongModel> get queue => List.unmodifiable(_queue);

  Stream<int?> get currentIndexStream => player.currentIndexStream;

  int get currentIndex {
    final index = player.currentIndex ?? _currentIndex;
    return index;
  }

  SongModel? get currentSong {
    final index = currentIndex;
    if (index >= 0 && index < _queue.length) {
      return _queue[index];
    }
    return null;
  }

  // 🔥 LOAD TIẾN TRÌNH
  Future<void> restoreLastSession(List<SongModel> songs) async {
    final prefs = await SharedPreferences.getInstance();

    final savedPath = prefs.getString("last_song");
    final savedPos = prefs.getInt("last_position") ?? 0;

    if (savedPath == null) return;

    final index = songs.indexWhere((s) => s.data == savedPath);
    if (index == -1) return;

    await setQueue(songs, initialIndex: index);

    await player.seek(Duration(milliseconds: savedPos));
  }

  Future<void> setQueue(List<SongModel> songs, {int initialIndex = 0}) async {
    try {
      final validSongs = songs.where((song) {
        final path = song.data;
        return path != null && path.trim().isNotEmpty;
      }).toList();

      _queue
        ..clear()
        ..addAll(validSongs);

      if (_queue.isEmpty) {
        _currentIndex = -1;
        await player.stop();
        return;
      }

      final safeIndex = initialIndex.clamp(0, _queue.length - 1);
      _currentIndex = safeIndex;

      final sources = _queue.map((song) {
        final path = song.data!;
        if (path.startsWith('http')) {
          return AudioSource.uri(Uri.parse(path));
        }
        return AudioSource.uri(Uri.file(path));
      }).toList();

      await player.stop();
      await player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        initialIndex: safeIndex,
      );

      await player.play();

      // 🔥 AUTO SAVE PROGRESS
      player.positionStream.listen((pos) async {
        final prefs = await SharedPreferences.getInstance();
        final song = currentSong;

        if (song != null) {
          prefs.setString("last_song", song.data ?? "");
          prefs.setInt("last_position", pos.inMilliseconds);
        }
      });

      // 🔥 AUTO NEXT
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _handleNext();
        }
      });
    } catch (e) {
      print('ERROR setQueue: $e');
    }
  }

  Future<void> playSong(SongModel song) async {
    final index = _queue.indexWhere((item) => item.id == song.id);

    if (index != -1) {
      await player.seek(Duration.zero, index: index);
      _currentIndex = index;
      await player.play();
      return;
    }

    await setQueue([song], initialIndex: 0);
  }

  Future<void> playSongAt(List<SongModel> songs, int index) async {
    if (songs.isEmpty) return;
    if (index < 0 || index >= songs.length) return;

    await setQueue(songs, initialIndex: index);
  }

  Future<void> play() async => player.play();
  Future<void> pause() async => player.pause();

  Future<void> next() async => _handleNext();

  Future<void> previous() async {
    if (_queue.isEmpty) return;

    _currentIndex--;
    if (_currentIndex < 0) _currentIndex = 0;

    await player.seek(Duration.zero, index: _currentIndex);
    await player.play();
  }

  void toggleShuffle() => shuffle = !shuffle;

  void toggleRepeat() {
    if (repeatMode == RepeatMode.off) {
      repeatMode = RepeatMode.all;
    } else if (repeatMode == RepeatMode.all) {
      repeatMode = RepeatMode.one;
    } else {
      repeatMode = RepeatMode.off;
    }
  }

  void _handleNext() async {
    if (_queue.isEmpty) return;

    if (repeatMode == RepeatMode.one) {
      await player.seek(Duration.zero);
      await player.play();
      return;
    }

    if (shuffle) {
      _currentIndex =
          DateTime.now().millisecondsSinceEpoch % _queue.length;
    } else {
      _currentIndex++;
    }

    if (_currentIndex >= _queue.length) {
      if (repeatMode == RepeatMode.all) {
        _currentIndex = 0;
      } else {
        return;
      }
    }

    await player.seek(Duration.zero, index: _currentIndex);
    await player.play();
  }

  void dispose() {
    player.dispose();
  }
}