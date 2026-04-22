import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/widgets/song_tile.dart';
import '../../data/models/song_model.dart';
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

  String query = "";

  // Kết quả tìm online
  List<SongModel> _onlineSongs = [];

  // chống gọi API liên tục khi gõ
  Timer? _debounce;

  // Emulator dùng 10.0.2.2
  final String searchApi =
      "http://10.0.2.2:3001/search";

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// =========================
  /// SEARCH ONLINE API
  /// =========================
  Future<List<SongModel>> searchOnline(
      String text,
      ) async {

    if (text.trim().isEmpty) {
      return [];
    }

    try {
      final res = await http.get(
        Uri.parse(
          "$searchApi?q=$text",
        ),
      );

      if (res.statusCode == 200) {

        final List data =
        jsonDecode(res.body);

        return data.map<SongModel>((item) {

          return SongModel(
            id: item["id"],
            title: item["title"],
            artist: item["artist"],
            data: item["url"],
            duration: null,
            albumId: null,
          );

        }).toList();
      }

    } catch (e) {
      print("Search API error: $e");
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {

    final q =
    query.toLowerCase().trim();

    /// fallback local như code cũ
    final localSongs =
    widget.controller.allSongs
        .where((song) {

      if (q.isEmpty) return true;

      return song.title
          .toLowerCase()
          .contains(q) ||

          song.artist
              .toLowerCase()
              .contains(q);

    }).toList();

    /// nếu có online -> ưu tiên online
    final songs =
    _onlineSongs.isNotEmpty
        ? _onlineSongs
        : localSongs;

    return Column(
      children: [

        Padding(
          padding: const EdgeInsets.fromLTRB(
              16, 12, 16, 8),
          child: TextField(

            onChanged: (value) {

              setState(() {
                query = value;
              });

              // debounce
              _debounce?.cancel();

              _debounce = Timer(
                const Duration(
                    milliseconds: 500),
                    () async {

                  final result =
                  await searchOnline(
                    value,
                  );

                  if (mounted) {
                    setState(() {
                      _onlineSongs =
                          result;
                    });
                  }

                },
              );
            },

            decoration: InputDecoration(
              hintText: 'Tìm bài hát...',
              prefixIcon: const Icon(
                Icons.search,
              ),
              filled: true,
              fillColor:
              const Color(0xFF121212),

              border:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(
                    16),
                borderSide:
                BorderSide.none,
              ),
            ),
          ),
        ),

        Expanded(
          child: songs.isEmpty
              ? const Center(
            child: Text(
              'Không tìm thấy bài hát phù hợp',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          )
              : ListView.builder(
            padding:
            const EdgeInsets.symmetric(
                horizontal: 12),
            itemCount: songs.length,

            itemBuilder: (_, i) {

              final song = songs[i];

              return SongTile(
                song: song,

                isFavorite:
                widget.controller
                    .isFavorite(song),

                onFavorite: () {

                  setState(() {
                    widget.controller
                        .toggleFavorite(
                        song);
                  });

                  widget.onChanged?.call();
                },

                onTap: () async {

                  await widget.controller
                      .playSpecificSong(
                    song,
                  );

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