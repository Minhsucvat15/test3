import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/services/audio_player_service.dart' as aps;
import '../../data/services/audio_player_service.dart' show AudioPlayerService;
import '../splash/splash_page.dart';
import 'widgets/vinyl_disc.dart';

class NowPlayingPage extends StatelessWidget {
  static const routeName = '/now-playing';
  const NowPlayingPage({super.key});

  static Route<void> route() {
    return PageRouteBuilder(
      settings: const RouteSettings(name: routeName),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, a, __) =>
          FadeTransition(opacity: a, child: const NowPlayingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioPlayerService>();
    final library = context.watch<LibraryRepository>();
    final song = audio.currentSong;
    final color = song?.colorValue != null
        ? Color(song!.colorValue!)
        : AppColors.brand;

    return Scaffold(
      body: Stack(
        children: [
          // Blurred background dùng cover hiện tại
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: song?.cover == null
                  ? Container(
                      key: const ValueKey('default'),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withOpacity(0.8),
                            AppColors.bgDark,
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      key: ValueKey(song!.cover),
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: song.cover!,
                          fit: BoxFit.cover,
                        ),
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                          child: Container(color: Colors.black.withOpacity(0.55)),
                        ),
                      ],
                    ),
            ),
          ),
          SafeArea(
            child: song == null
                ? _empty(context)
                : _content(context, song, library, audio, color),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Column(
      children: [
        const _Header(title: 'Đang phát'),
        const Expanded(
          child: Center(
            child: Text(
              'Chưa có bài hát nào',
              style: TextStyle(color: Colors.white60),
            ),
          ),
        ),
      ],
    );
  }

  Widget _content(
    BuildContext context,
    song,
    LibraryRepository library,
    AudioPlayerService audio,
    Color color,
  ) {
    return Column(
      children: [
        _Header(
          title: song.album ?? 'Đang phát',
          onMore: () => _showMore(context, song.id),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Center(
            child: StreamBuilder<PlayerState>(
              stream: audio.player.playerStateStream,
              builder: (_, snap) {
                final playing = snap.data?.playing ?? false;
                return VinylDisc(imageUrl: song.cover, spinning: playing);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    iconSize: 30,
                    onPressed: () => library.toggleFavorite(song),
                    icon: Icon(
                      library.isFavorite(song.id)
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: library.isFavorite(song.id)
                          ? Colors.redAccent
                          : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<Duration?>(
                stream: audio.player.durationStream,
                builder: (_, dSnap) {
                  final total = dSnap.data ?? Duration.zero;
                  return StreamBuilder<Duration>(
                    stream: audio.player.positionStream,
                    builder: (_, pSnap) {
                      final pos = pSnap.data ?? Duration.zero;
                      final maxMs = total.inMilliseconds == 0
                          ? 1.0
                          : total.inMilliseconds.toDouble();
                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              activeTrackColor: color,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                              overlayShape: SliderComponentShape.noOverlay,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 7),
                            ),
                            child: Slider(
                              value: pos.inMilliseconds
                                  .toDouble()
                                  .clamp(0, maxMs),
                              max: maxMs,
                              onChanged: (v) => audio.player
                                  .seek(Duration(milliseconds: v.toInt())),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(formatDuration(pos),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.white70)),
                                Text(formatDuration(total),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.white70)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 14),
              StreamBuilder<PlayerState>(
                stream: audio.player.playerStateStream,
                builder: (_, snap) {
                  final playing = snap.data?.playing ?? false;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        iconSize: 26,
                        onPressed: audio.toggleShuffle,
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: audio.shuffle ? color : Colors.white70,
                        ),
                      ),
                      IconButton(
                        iconSize: 36,
                        onPressed: audio.previous,
                        icon: const Icon(Icons.skip_previous_rounded),
                      ),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.brandGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brand.withOpacity(0.45),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: IconButton(
                          iconSize: 38,
                          color: Colors.black,
                          onPressed: () =>
                              playing ? audio.pause() : audio.play(),
                          icon: Icon(playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded),
                        ),
                      ),
                      IconButton(
                        iconSize: 36,
                        onPressed: audio.next,
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                      IconButton(
                        iconSize: 26,
                        onPressed: audio.toggleRepeat,
                        icon: Icon(
                          audio.repeatMode == aps.RepeatMode.one
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                          color: audio.repeatMode == aps.RepeatMode.off
                              ? Colors.white70
                              : color,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ],
    );
  }

  void _showMore(BuildContext context, String songId) {
    final library = context.read<LibraryRepository>();
    final catalog = context.read<CatalogHolder>().catalog;
    final song = catalog?.songs.where((s) => s.id == songId).cast<dynamic>().firstWhere(
          (s) => s != null,
          orElse: () => null,
        );
    if (song == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('Thêm vào playlist'),
              onTap: () {
                Navigator.pop(context);
                _showAddToPlaylist(context, songId);
              },
            ),
            ListTile(
              leading: Icon(
                library.isFavorite(songId)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: library.isFavorite(songId) ? Colors.redAccent : null,
              ),
              title: const Text('Yêu thích / bỏ yêu thích'),
              onTap: () {
                library.toggleFavorite(song);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylist(BuildContext context, String songId) {
    final library = context.read<LibraryRepository>();
    if (library.playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa có playlist nào')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (final p in library.playlists)
              ListTile(
                leading: CircleAvatar(backgroundColor: Color(p.colorValue)),
                title: Text(p.name),
                trailing: p.songIds.contains(songId)
                    ? const Icon(Icons.check, color: AppColors.brand)
                    : null,
                onTap: () async {
                  await library.addSongToPlaylist(p.id, songId);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã thêm vào "${p.name}"')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback? onMore;
  const _Header({required this.title, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (onMore != null)
            IconButton(onPressed: onMore, icon: const Icon(Icons.more_horiz))
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
