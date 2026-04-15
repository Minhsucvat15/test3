import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/services/audio_player_service.dart';

class NowPlayingPage extends StatelessWidget {
  final AudioPlayerService audioPlayerService;

  const NowPlayingPage({
    super.key,
    required this.audioPlayerService,
  });

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final player = audioPlayerService.player;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1DB954),
              Color(0xFF121212),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (context, snapshot) {
              final song = audioPlayerService.currentSong;
              final isPlaying = snapshot.data?.playing ?? false;

              return Column(
                children: [
                  /// HEADER
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                      const Expanded(
                        child: Text(
                          "Now Playing",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),

                  const SizedBox(height: 30),

                  /// ALBUM (GLASS + SHADOW)
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1ED760),
                          Color(0xFF0D8BFF),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.music_note,
                        size: 120, color: Colors.white),
                  ),

                  const SizedBox(height: 30),

                  /// TITLE
                  Text(
                    song?.title ?? "",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    song?.artist ?? "",
                    style: const TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 30),

                  /// PROGRESS
                  StreamBuilder<Duration?>(
                    stream: player.durationStream,
                    builder: (_, d) {
                      final total = d.data ?? Duration.zero;

                      return StreamBuilder<Duration>(
                        stream: player.positionStream,
                        builder: (_, p) {
                          final pos = p.data ?? Duration.zero;

                          return Column(
                            children: [
                              Slider(
                                value: pos.inMilliseconds.toDouble(),
                                max: total.inMilliseconds == 0
                                    ? 1
                                    : total.inMilliseconds.toDouble(),
                                onChanged: (v) {
                                  player.seek(
                                      Duration(milliseconds: v.toInt()));
                                },
                              ),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_format(pos)),
                                  Text(_format(total)),
                                ],
                              )
                            ],
                          );
                        },
                      );
                    },
                  ),

                  const Spacer(),

                  /// CONTROLS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: audioPlayerService.toggleShuffle,
                        icon: const Icon(Icons.shuffle),
                      ),
                      IconButton(
                        onPressed: audioPlayerService.previous,
                        icon: const Icon(Icons.skip_previous),
                      ),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1ED760),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          iconSize: 35,
                          color: Colors.black,
                          onPressed: () {
                            isPlaying
                                ? audioPlayerService.pause()
                                : audioPlayerService.play();
                          },
                          icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow),
                        ),
                      ),
                      IconButton(
                        onPressed: audioPlayerService.next,
                        icon: const Icon(Icons.skip_next),
                      ),
                      IconButton(
                        onPressed: audioPlayerService.toggleRepeat,
                        icon: const Icon(Icons.repeat),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}