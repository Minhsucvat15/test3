import 'package:flutter/material.dart';

import '../../core/widgets/glass_card.dart';
import '../../core/widgets/mini_player.dart';
import '../../core/widgets/song_tile.dart';
import '../../data/models/song_model.dart';
import '../../data/services/audio_player_service.dart';
import '../../data/services/media_query_service.dart';
import '../../data/services/music_controller.dart';
import '../library/library_page.dart';
import '../player/now_playing_page.dart';
import '../search/search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MediaQueryService _mediaQueryService = MediaQueryService();
  final AudioPlayerService _audioPlayerService = AudioPlayerService();

  late MusicController _musicController;

  List<SongModel> _songs = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _musicController = MusicController(_audioPlayerService);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSongs();
    });
  }

  Future<void> _loadSongs({bool force = false}) async {
    if (_loaded && !force) return;
    _loaded = true;

    try {
      setState(() {
        _isLoading = true;
      });

      final songs = await _mediaQueryService.getSongsSafe();

      if (!mounted) return;

      setState(() {
        _songs = songs;
        _musicController.setSongs(songs);
        _isLoading = false;
      });
    } catch (e) {
      print('LOAD ERROR: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _playSong(int index) async {
    try {
      if (index < 0 || index >= _songs.length) return;

      await _musicController.playSongAt(index);

      if (!mounted) return;

      setState(() {});

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NowPlayingPage(
            audioPlayerService: _audioPlayerService,
          ),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      print('PLAY ERROR: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1F2E),
              Color(0xFF10131A),
              Color(0xFF090B10),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(child: _buildPage()),
              MiniPlayer(audioPlayerService: _audioPlayerService),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: const Color(0xFF11141B),
        indicatorColor: const Color(0x331ED760),
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Tìm kiếm',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_rounded),
            label: 'Thư viện',
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    if (_selectedIndex == 0) {
      return _buildHomeContent();
    }

    if (_selectedIndex == 1) {
      return SearchPage(
        controller: _musicController,
        onChanged: () => setState(() {}),
      );
    }

    return LibraryPage(
      controller: _musicController,
      onChanged: () => setState(() {}),
    );
  }

  Widget _buildHomeContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 20),
          _quickActions(),
          const SizedBox(height: 24),
          const Text(
            'Bài hát trong máy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0x221ED760),
          child: Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xin chào',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            Text(
              'Nghe gì hôm nay?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            _loaded = false;
            _loadSongs(force: true);
          },
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
            },
            child: GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.favorite_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Favorites (${_musicController.favoriteSongs.length})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
            },
            child: GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.history_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Gần đây (${_musicController.recentSongs.length})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_songs.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy bài hát',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: _songs.length,
      itemBuilder: (_, i) {
        final song = _songs[i];
        return SongTile(
          song: song,
          isFavorite: _musicController.isFavorite(song),
          onFavorite: () {
            setState(() {
              _musicController.toggleFavorite(song);
            });
          },
          onTap: () => _playSong(i),
        );
      },
    );
  }
}