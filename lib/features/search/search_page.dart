import 'package:flutter/material.dart';

import '../../core/widgets/song_tile.dart';
import '../../data/services/music_controller.dart';

class SearchPage extends StatefulWidget {
  final MusicController controller;
  final VoidCallback? onChanged;

  const SearchPage({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase().trim();

    final songs = widget.controller.allSongs.where((song) {
      if (q.isEmpty) return true;
      return song.title.toLowerCase().contains(q) ||
          song.artist.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (value) {
              setState(() {
                query = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm bài hát...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFF121212),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: songs.isEmpty
              ? const Center(
            child: Text(
              'Không tìm thấy bài hát phù hợp',
              style: TextStyle(color: Colors.white70),
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
}