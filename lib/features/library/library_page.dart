import 'package:flutter/material.dart';

import '../../core/widgets/song_tile.dart';
import '../../data/models/song_model.dart';
import '../../data/services/music_controller.dart';

class LibraryPage extends StatefulWidget {
  final MusicController controller;
  final VoidCallback? onChanged;

  const LibraryPage({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    List<SongModel> songs;

    if (tab == 0) {
      songs = widget.controller.allSongs;
    } else if (tab == 1) {
      songs = widget.controller.favoriteSongs;
    } else {
      songs = widget.controller.recentSongs;
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _tabButton('Tất cả', 0),
            _tabButton('Yêu thích', 1),
            _tabButton('Gần đây', 2),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: songs.isEmpty
              ? Center(
            child: Text(
              tab == 1
                  ? 'Chưa có bài hát yêu thích'
                  : tab == 2
                  ? 'Chưa có bài hát gần đây'
                  : 'Không có bài hát',
              style: const TextStyle(color: Colors.white70),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: songs.length,
            itemBuilder: (_, i) {
              final song = songs[i];
              return SongTile(
                song: song,
                isFavorite: widget.controller.isFavorite(song),
                onFavorite: () {
                  setState(() {
                    widget.controller.toggleFavorite(song);
                  });
                  widget.onChanged?.call();
                },
                onTap: () async {
                  await widget.controller.playSpecificSong(song);
                  widget.onChanged?.call();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tabButton(String text, int index) {
    final isSelected = tab == index;

    return TextButton(
      onPressed: () {
        setState(() {
          tab = index;
        });
      },
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? const Color(0xFF1ED760) : Colors.white70,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}