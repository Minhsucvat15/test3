import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/song_tile.dart';
import '../../data/models/playlist_model.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/services/audio_player_service.dart';
import '../player/now_playing_page.dart';
import '../splash/splash_page.dart';

class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;
  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryRepository>();
    final catalog = context.watch<CatalogHolder>().catalog;
    final audio = context.watch<AudioPlayerService>();

    final playlist = library.playlists.where(
      (p) => p.id == widget.playlistId,
    ).cast<PlaylistModel?>().firstWhere(
          (p) => p != null,
          orElse: () => null,
        );

    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.error_outline,
          title: 'Playlist không tồn tại',
        ),
      );
    }

    final allSongs = catalog?.songs ?? const <SongModel>[];
    final songs = playlist.songIds
        .map((id) =>
            allSongs.where((s) => s.id == id).cast<SongModel?>().firstWhere(
                  (s) => s != null,
                  orElse: () => null,
                ))
        .whereType<SongModel>()
        .toList();

    final c = Color(playlist.colorValue);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: c.withOpacity(0.4),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'pl_${playlist.id}',
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [c, c.withOpacity(0.4), AppColors.bgDark],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 70, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.queue_music_rounded,
                            color: Colors.white, size: 56),
                        const SizedBox(height: 8),
                        Text(
                          playlist.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (playlist.description?.isNotEmpty == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              playlist.description!,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '${songs.length} bài hát',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Phát tất cả',
                      icon: Icons.play_arrow_rounded,
                      onPressed: songs.isEmpty
                          ? null
                          : () async {
                              await audio.playSongAt(songs, 0);
                              if (!context.mounted) return;
                              Navigator.push(
                                  context, NowPlayingPage.route());
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Thêm bài',
                      icon: Icons.add_rounded,
                      secondary: true,
                      onPressed: () => _showPicker(context, playlist, allSongs),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (songs.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.music_note_rounded,
                title: 'Playlist trống',
                subtitle: 'Bấm "Thêm bài" để thêm bài hát.',
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
                    onMore: () => _showSongMenu(context, playlist, s),
                    onTap: () async {
                      await audio.playSongAt(songs, i);
                      if (!context.mounted) return;
                      Navigator.push(context, NowPlayingPage.route());
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

  void _showSongMenu(
      BuildContext context, PlaylistModel playlist, SongModel s) {
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
              leading: const Icon(Icons.remove_circle_outline,
                  color: Colors.redAccent),
              title: const Text('Xoá khỏi playlist',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                await context
                    .read<LibraryRepository>()
                    .removeSongFromPlaylist(playlist.id, s.id);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(
    BuildContext context,
    PlaylistModel playlist,
    List<SongModel> all,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDark2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) {
          return _SongPicker(
            playlist: playlist,
            allSongs: all,
            controller: scrollCtrl,
          );
        },
      ),
    );
  }
}

class _SongPicker extends StatefulWidget {
  final PlaylistModel playlist;
  final List<SongModel> allSongs;
  final ScrollController controller;
  const _SongPicker({
    required this.playlist,
    required this.allSongs,
    required this.controller,
  });

  @override
  State<_SongPicker> createState() => _SongPickerState();
}

class _SongPickerState extends State<_SongPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryRepository>();
    final filtered = widget.allSongs.where((s) {
      if (_q.isEmpty) return true;
      final q = _q.toLowerCase();
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Thêm bài vào playlist',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: const InputDecoration(
              hintText: 'Tìm bài để thêm...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              controller: widget.controller,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final s = filtered[i];
                final inPl = widget.playlist.songIds.contains(s.id);
                return ListTile(
                  leading: const Icon(Icons.music_note_rounded),
                  title: Text(s.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(s.artist,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: Icon(
                      inPl
                          ? Icons.check_circle_rounded
                          : Icons.add_circle_outline,
                      color: inPl ? AppColors.brand : Colors.white,
                    ),
                    onPressed: () async {
                      if (inPl) {
                        await library.removeSongFromPlaylist(
                            widget.playlist.id, s.id);
                      } else {
                        await library.addSongToPlaylist(
                            widget.playlist.id, s.id);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
