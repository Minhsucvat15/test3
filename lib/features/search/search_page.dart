import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/song_tile.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/services/audio_player_service.dart';
import '../player/now_playing_page.dart';
import '../splash/splash_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _ctrl = TextEditingController();
  String _query = '';
  Timer? _debounce;
  List<SongModel> _onlineResults = [];
  bool _online = false;

  static const _api = 'http://10.0.2.2:3001/search';

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _searchOnline(String text) async {
    if (text.trim().isEmpty) {
      setState(() => _onlineResults = []);
      return;
    }
    try {
      setState(() => _online = true);
      final uri = Uri.parse(_api).replace(queryParameters: {'q': text});
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        if (!mounted) return;
        setState(() {
          _onlineResults = list
              .map((e) =>
                  SongModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _onlineResults = []);
    } finally {
      if (mounted) setState(() => _online = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogHolder>().catalog;
    final library = context.watch<LibraryRepository>();
    final audio = context.watch<AudioPlayerService>();
    final all = catalog?.songs ?? const <SongModel>[];

    final q = _query.trim().toLowerCase();
    final local = all.where((s) {
      if (q.isEmpty) return true;
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q) ||
          (s.album ?? '').toLowerCase().contains(q);
    }).toList();

    final results =
        _onlineResults.isNotEmpty ? _onlineResults : local;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              const Text(
                'Tìm kiếm',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (_online)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _ctrl,
            onChanged: (v) {
              setState(() => _query = v);
              _debounce?.cancel();
              _debounce = Timer(
                const Duration(milliseconds: 400),
                () => _searchOnline(v),
              );
            },
            decoration: InputDecoration(
              hintText: 'Tên bài, nghệ sĩ, album...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _ctrl.clear();
                        setState(() {
                          _query = '';
                          _onlineResults = [];
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: results.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Không tìm thấy bài hát',
                  subtitle: 'Thử từ khóa khác hoặc duyệt theo thể loại nhé.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 110),
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final s = results[i];
                    final isPlaying = audio.currentSong?.id == s.id;
                    return SongTile(
                      song: s,
                      isFavorite: library.isFavorite(s.id),
                      playing: isPlaying,
                      onFavorite: () => library.toggleFavorite(s),
                      onTap: () async {
                        await audio.playSongAt(results, i);
                        if (!mounted) return;
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
