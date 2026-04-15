import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/services/audio_player_service.dart';
import '../../features/player/now_playing_page.dart';
import 'glass_card.dart';

class MiniPlayer extends StatelessWidget {
  final AudioPlayerService audioPlayerService;

  const MiniPlayer({
    super.key,
    required this.audioPlayerService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: audioPlayerService.player.playerStateStream,
      builder: (context, snapshot) {
        final song = audioPlayerService.currentSong;
        final isPlaying = snapshot.data?.playing ?? false;

        if (song == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NowPlayingPage(
                    audioPlayerService: audioPlayerService,
                  ),
                ),
              );
            },
            child: GlassCard(
              borderRadius: 26,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// 🎵 PROGRESS BAR
                  StreamBuilder<Duration>(
                    stream: audioPlayerService.player.positionStream,
                    builder: (_, pos) {
                      final duration =
                          audioPlayerService.player.duration ?? Duration.zero;
                      final p = pos.data ?? Duration.zero;

                      double progress = 0;
                      if (duration.inMilliseconds > 0) {
                        progress =
                            p.inMilliseconds / duration.inMilliseconds;
                      }

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF1ED760),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  /// 🎧 MAIN ROW
                  Row(
                    children: [
                      /// COVER
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1ED760),
                              Color(0xFF0D8BFF),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// TEXT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// CONTROLS
                      IconButton(
                        onPressed: audioPlayerService.previous,
                        icon: const Icon(Icons.skip_previous_rounded),
                      ),
                      IconButton(
                        onPressed: () {
                          isPlaying
                              ? audioPlayerService.pause()
                              : audioPlayerService.play();
                        },
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          size: 30,
                        ),
                      ),
                      IconButton(
                        onPressed: audioPlayerService.next,
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}