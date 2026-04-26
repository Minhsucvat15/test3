import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../data/services/audio_player_service.dart';
import '../../features/player/now_playing_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioPlayerService>();
    final song = audio.currentSong;
    if (song == null) return const SizedBox.shrink();
    final palette = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, NowPlayingPage.route());
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: dark ? null : palette.card,
            gradient: dark
                ? LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.07),
                      Colors.white.withOpacity(0.03),
                    ],
                  )
                : null,
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<Duration>(
                stream: audio.player.positionStream,
                builder: (_, p) {
                  final pos = p.data ?? Duration.zero;
                  final dur = audio.player.duration ?? Duration.zero;
                  final v = dur.inMilliseconds == 0
                      ? 0.0
                      : pos.inMilliseconds / dur.inMilliseconds;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: v.clamp(0, 1),
                      minHeight: 3,
                      backgroundColor: palette.subtleFill,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.brand),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: song.cover == null
                          ? Container(
                              decoration: const BoxDecoration(
                                gradient: AppColors.brandGradient,
                              ),
                              child: const Icon(Icons.music_note,
                                  color: Colors.white),
                            )
                          : CachedNetworkImage(
                              imageUrl: song.cover!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<PlayerState>(
                    stream: audio.player.playerStateStream,
                    builder: (_, snap) {
                      final playing = snap.data?.playing ?? false;
                      return Row(
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: audio.previous,
                            icon: const Icon(Icons.skip_previous_rounded),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                playing ? audio.pause() : audio.play(),
                            icon: Icon(
                              playing
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded,
                              size: 30,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: audio.next,
                            icon: const Icon(Icons.skip_next_rounded),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
