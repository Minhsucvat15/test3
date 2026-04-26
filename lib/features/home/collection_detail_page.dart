import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/song_tile.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/services/audio_player_service.dart';
import '../player/now_playing_page.dart';

/// Page chung dùng cho Mix / Suggested playlist / Album / Category.
class CollectionDetailPage extends StatelessWidget {
  final String heroTag;
  final String title;
  final String? subtitle;
  final String? cover;
  final int colorValue;
  final List<SongModel> songs;
  final IconData fallbackIcon;

  const CollectionDetailPage({
    super.key,
    required this.heroTag,
    required this.title,
    required this.songs,
    required this.colorValue,
    this.subtitle,
    this.cover,
    this.fallbackIcon = Icons.queue_music_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);
    final library = context.watch<LibraryRepository>();
    final audio = context.watch<AudioPlayerService>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: color.withOpacity(0.4),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: heroTag,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (cover != null)
                      CachedNetworkImage(
                        imageUrl: cover!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: color),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                            Colors.black,
                          ],
                          stops: const [0, 0.6, 1],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                subtitle!,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            '${songs.length} bài hát',
                            style: const TextStyle(color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: PrimaryButton(
                label: 'Phát tất cả',
                icon: Icons.play_arrow_rounded,
                onPressed: songs.isEmpty
                    ? null
                    : () async {
                        await audio.playSongAt(songs, 0);
                        if (!context.mounted) return;
                        Navigator.push(context, NowPlayingPage.route());
                      },
              ),
            ),
          ),
          if (songs.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.music_off_rounded,
                title: 'Không có bài hát',
              ),
            )
          else
            SliverList.builder(
              itemCount: songs.length,
              itemBuilder: (_, i) {
                final s = songs[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SongTile(
                    song: s,
                    isFavorite: library.isFavorite(s.id),
                    playing: audio.currentSong?.id == s.id,
                    onFavorite: () => library.toggleFavorite(s),
                    onTap: () async {
                      await audio.playSongAt(songs, i);
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NowPlayingPage(),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }
}
