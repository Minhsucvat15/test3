import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/models/song_model.dart';
import '../theme/app_theme.dart';

class SongTile extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onMore;
  final bool isFavorite;
  final bool playing;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.onFavorite,
    this.onMore,
    this.isFavorite = false,
    this.playing = false,
  });

  @override
  Widget build(BuildContext context) {
    final artist = song.artist.trim().isEmpty ? 'Không rõ nghệ sĩ' : song.artist;
    final cover = song.cover;
    final color = song.colorValue != null
        ? Color(song.colorValue!)
        : const Color(0xFF1ED760);
    final palette = AppPalette.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: cover == null
                    ? _fallback(color)
                    : CachedNetworkImage(
                        imageUrl: cover,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _fallback(color),
                        errorWidget: (_, __, ___) => _fallback(color),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (playing) ...[
                        const _PlayingDot(),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: playing ? const Color(0xFF1ED760) : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (onFavorite != null)
              IconButton(
                onPressed: onFavorite,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.redAccent : palette.textMuted,
                ),
              ),
            if (onMore != null)
              IconButton(
                onPressed: onMore,
                icon: const Icon(Icons.more_vert),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fallback(Color c) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c, c.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.music_note, color: Colors.white),
        ),
      );
}

class _PlayingDot extends StatefulWidget {
  const _PlayingDot();

  @override
  State<_PlayingDot> createState() => _PlayingDotState();
}

class _PlayingDotState extends State<_PlayingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final h = 6 + (_c.value + i * 0.25) % 1 * 8;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                width: 3,
                height: h,
                decoration: BoxDecoration(
                  color: const Color(0xFF1ED760),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
