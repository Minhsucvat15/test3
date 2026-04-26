import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song_model.dart';

enum RepeatMode { off, one, all }

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer();
  final Random _random = Random();

  final List<SongModel> _queue = [];
  int _currentIndex = -1;

  bool _shuffle = false;
  RepeatMode _repeatMode = RepeatMode.off;

  bool get shuffle => _shuffle;
  RepeatMode get repeatMode => _repeatMode;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<int?>? _idxSub;
  DateTime _lastProgressSave = DateTime.fromMillisecondsSinceEpoch(0);

  /// Callback khi có bài hát thực sự được phát (cập nhật recent)
  void Function(SongModel song)? onPlayed;

  List<SongModel> get queue => List.unmodifiable(_queue);
  Stream<int?> get currentIndexStream => player.currentIndexStream;

  int get currentIndex {
    return player.currentIndex ?? _currentIndex;
  }

  SongModel? get currentSong {
    final i = currentIndex;
    if (i >= 0 && i < _queue.length) return _queue[i];
    return null;
  }

  Future<void> restoreLastSession(List<SongModel> songs) async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('last_song_id');
    final savedPos = prefs.getInt('last_position') ?? 0;
    if (savedId == null) return;
    final idx = songs.indexWhere((s) => s.id == savedId);
    if (idx == -1) return;
    await setQueue(
      songs,
      initialIndex: idx,
      autoPlay: false,
      initialPosition: Duration(milliseconds: savedPos),
    );
  }

  Future<void> setQueue(
    List<SongModel> songs, {
    int initialIndex = 0,
    bool autoPlay = true,
    Duration? initialPosition,
  }) async {
    try {
      final valid = songs
          .where((s) => s.data != null && s.data!.trim().isNotEmpty)
          .toList();

      _queue
        ..clear()
        ..addAll(valid);

      if (_queue.isEmpty) {
        _currentIndex = -1;
        await player.stop();
        notifyListeners();
        return;
      }

      final safe = initialIndex.clamp(0, _queue.length - 1);
      _currentIndex = safe;

      final sources = _queue.map((s) {
        final p = s.data!;
        return p.startsWith('http')
            ? AudioSource.uri(Uri.parse(p))
            : AudioSource.uri(Uri.file(p));
      }).toList();

      await player.stop();
      await player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        initialIndex: safe,
        initialPosition: initialPosition ?? Duration.zero,
      );

      await _positionSub?.cancel();
      await _stateSub?.cancel();
      await _idxSub?.cancel();

      _positionSub = player.positionStream.listen((pos) async {
        final now = DateTime.now();
        if (now.difference(_lastProgressSave) <
            const Duration(seconds: 2)) return;
        _lastProgressSave = now;
        final song = currentSong;
        if (song == null) return;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_song_id', song.id);
        await prefs.setInt('last_position', pos.inMilliseconds);
      });

      _stateSub = player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _handleNext();
        }
      });

      _idxSub = player.currentIndexStream.listen((i) {
        notifyListeners();
        if (i != null && i >= 0 && i < _queue.length) {
          onPlayed?.call(_queue[i]);
        }
      });

      notifyListeners();

      if (autoPlay) {
        await player.play();
      }
    } catch (e) {
      debugPrint('setQueue error: $e');
    }
  }

  Future<void> playSong(SongModel song) async {
    final i = _queue.indexWhere((s) => s.id == song.id);
    if (i != -1) {
      await player.seek(Duration.zero, index: i);
      _currentIndex = i;
      await player.play();
      onPlayed?.call(song);
      notifyListeners();
      return;
    }
    await setQueue([song]);
    onPlayed?.call(song);
  }

  Future<void> playSongAt(List<SongModel> songs, int index) async {
    if (songs.isEmpty || index < 0 || index >= songs.length) return;
    await setQueue(songs, initialIndex: index);
    final s = songs[index.clamp(0, songs.length - 1)];
    onPlayed?.call(s);
  }

  Future<void> play() async {
    await player.play();
    notifyListeners();
  }

  Future<void> pause() async {
    await player.pause();
    notifyListeners();
  }

  Future<void> next() => _handleNext();

  Future<void> previous() async {
    if (_queue.isEmpty) return;
    int i = currentIndex;
    if (i <= 0) {
      i = _repeatMode == RepeatMode.all ? _queue.length - 1 : 0;
    } else {
      i--;
    }
    _currentIndex = i;
    await player.seek(Duration.zero, index: i);
    await player.play();
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    _repeatMode = switch (_repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    notifyListeners();
  }

  Future<void> _handleNext() async {
    if (_queue.isEmpty) return;
    if (_repeatMode == RepeatMode.one) {
      await player.seek(Duration.zero);
      await player.play();
      return;
    }
    int next;
    if (_shuffle) {
      if (_queue.length == 1) {
        next = 0;
      } else {
        final cur = currentIndex;
        do {
          next = _random.nextInt(_queue.length);
        } while (next == cur);
      }
    } else {
      next = currentIndex + 1;
    }
    if (next >= _queue.length) {
      if (_repeatMode == RepeatMode.all) {
        next = 0;
      } else {
        return;
      }
    }
    _currentIndex = next;
    await player.seek(Duration.zero, index: next);
    await player.play();
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _idxSub?.cancel();
    player.dispose();
    super.dispose();
  }
}
