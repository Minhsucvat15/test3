import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/song_tile.dart';
import '../../data/models/playlist_model.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/services/audio_player_service.dart';
import '../player/now_playing_page.dart';
import '../splash/splash_page.dart';
import 'playlist_detail_page.dart';
import 'playlist_form_dialog.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryRepository>();
    final catalog = context.watch<CatalogHolder>().catalog;

    final songs = catalog?.songs ?? const <SongModel>[];
    final favorites = library.favoriteIds
        .map((id) => songs.where((s) => s.id == id).cast<SongModel?>())
        .map((it) => it.isEmpty ? null : it.first)
        .whereType<SongModel>()
        .toList();
    final recents = library.recentIds
        .map((id) => songs.where((s) => s.id == id).cast<SongModel?>())
        .map((it) => it.isEmpty ? null : it.first)
        .whereType<SongModel>()
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              const Text(
                'Thư viện',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  final created = await showPlaylistFormDialog(context);
                  if (!mounted) return;
                  if (created != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã tạo "${created.name}"')),
                    );
                  }
                },
                icon: const Icon(Icons.playlist_add_rounded),
                tooltip: 'Tạo playlist',
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tab,
          indicatorColor: AppColors.brand,
          labelColor: AppColors.brand,
          unselectedLabelColor: AppPalette.of(context).textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: 'Playlists'),
            Tab(text: 'Yêu thích'),
            Tab(text: 'Gần đây'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _PlaylistsTab(library: library, songs: songs),
              _SongsTab(songs: favorites, emptyTitle: 'Chưa có bài hát yêu thích'),
              _SongsTab(
                songs: recents,
                emptyTitle: 'Chưa có lịch sử nghe',
                onClear: recents.isEmpty ? null : library.clearRecent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  final LibraryRepository library;
  final List<SongModel> songs;
  const _PlaylistsTab({required this.library, required this.songs});

  @override
  Widget build(BuildContext context) {
    final pls = library.playlists;
    if (pls.isEmpty) {
      return EmptyState(
        icon: Icons.queue_music_rounded,
        title: 'Chưa có playlist',
        subtitle: 'Tạo playlist mới để gom các bài bạn yêu thích.',
        action: FilledButton.icon(
          onPressed: () => showPlaylistFormDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Tạo playlist'),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: pls.length,
      itemBuilder: (_, i) =>
          _PlaylistCard(playlist: pls[i], allSongs: songs, library: library),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final PlaylistModel playlist;
  final List<SongModel> allSongs;
  final LibraryRepository library;
  const _PlaylistCard({
    required this.playlist,
    required this.allSongs,
    required this.library,
  });

  @override
  Widget build(BuildContext context) {
    final c = Color(playlist.colorValue);
    final n = playlist.songIds.length;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistDetailPage(playlistId: playlist.id),
        ),
      ),
      onLongPress: () => _showMenu(context),
      child: Hero(
        tag: 'pl_${playlist.id}',
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [c, c.withOpacity(0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: c.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.queue_music_rounded,
                  size: 38, color: Colors.white),
              const Spacer(),
              Text(
                playlist.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$n bài hát',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Sửa playlist'),
              onTap: () async {
                Navigator.pop(context);
                await showPlaylistFormDialog(context, edit: playlist);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              title: const Text('Xoá playlist',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Xoá playlist?'),
                    content: Text('Bạn có chắc muốn xoá "${playlist.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Huỷ'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: const Text('Xoá'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await library.deletePlaylist(playlist.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SongsTab extends StatelessWidget {
  final List<SongModel> songs;
  final String emptyTitle;
  final VoidCallback? onClear;
  const _SongsTab({
    required this.songs,
    required this.emptyTitle,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryRepository>();
    final audio = context.watch<AudioPlayerService>();

    if (songs.isEmpty) {
      return EmptyState(
        icon: Icons.music_off_rounded,
        title: emptyTitle,
      );
    }
    return Column(
      children: [
        if (onClear != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('Xoá hết'),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 110),
            itemCount: songs.length,
            itemBuilder: (_, i) {
              final s = songs[i];
              final isPlaying = audio.currentSong?.id == s.id;
              return SongTile(
                song: s,
                isFavorite: library.isFavorite(s.id),
                playing: isPlaying,
                onFavorite: () => library.toggleFavorite(s),
                onTap: () async {
                  await audio.playSongAt(songs, i);
                  if (!context.mounted) return;
                  Navigator.push(context, NowPlayingPage.route());
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
