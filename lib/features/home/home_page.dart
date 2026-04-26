import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/services/audio_player_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/catalog_service.dart';
import '../player/now_playing_page.dart';
import '../splash/splash_page.dart';
import 'collection_detail_page.dart';
import 'widgets/section_header.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogHolder>().catalog;
    final auth = context.watch<AuthService>();

    if (catalog == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final palette = AppPalette.of(context);
    final user = auth.currentUser;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        _Header(name: user?.displayName ?? 'Khách', seed: user?.email ?? 'g'),
        const SizedBox(height: 18),
        _FeaturedCarousel(items: catalog.featured, catalog: catalog),
        const SectionHeader(
          title: 'Mix nổi bật',
          subtitle: 'Tuyển chọn dành cho bạn',
        ),
        _MixRow(catalog: catalog),
        const SectionHeader(
          title: 'Gợi ý playlist',
          subtitle: 'Phù hợp với tâm trạng hôm nay',
        ),
        _SuggestionRow(catalog: catalog),
        const SectionHeader(
          title: 'Chủ đề & thể loại',
          subtitle: 'Khám phá theo phong cách',
        ),
        _CategoryGrid(catalog: catalog),
        SectionHeader(
          title: 'Bảng xếp hạng',
          subtitle: 'Top nghe nhiều nhất tuần này',
          onSeeAll: () {
            final sorted = [...catalog.songs]
              ..sort((a, b) => b.playCount.compareTo(a.playCount));
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CollectionDetailPage(
                  heroTag: 'rank_all',
                  title: 'Bảng xếp hạng',
                  subtitle: 'Top nghe nhiều nhất',
                  colorValue: 0xFFFF6B9D,
                  songs: sorted,
                  fallbackIcon: Icons.leaderboard_rounded,
                ),
              ),
            );
          },
        ),
        _RankingList(catalog: catalog),
        const SectionHeader(
          title: 'Album mới',
          subtitle: 'Vừa lên kệ',
        ),
        _AlbumRow(catalog: catalog),
        const SizedBox(height: 8),
        Text(
          '🎵  Tổng ${catalog.songs.length} bài • ${catalog.albums.length} album',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.textFaint, fontSize: 12),
        ),
      ],
    );
  }
}

// ============ Header (giữ nguyên ý từ phiên bản trước, gọn lại) ============

class _Header extends StatelessWidget {
  final String name;
  final String seed;
  const _Header({required this.name, required this.seed});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Xin chào,', style: TextStyle(color: palette.textMuted)),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        _Avatar(seed: seed),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String seed;
  const _Avatar({required this.seed});

  @override
  Widget build(BuildContext context) {
    final hash = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    final hue = (hash * 47) % 360;
    final c = HSLColor.fromAHSL(1, hue.toDouble(), 0.6, 0.55).toColor();
    final letter = seed.isEmpty ? '?' : seed[0].toUpperCase();
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [c, c.withOpacity(0.5)]),
        boxShadow: [
          BoxShadow(
            color: c.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ============ FEATURED CAROUSEL ============

class _FeaturedCarousel extends StatefulWidget {
  final List<FeaturedItem> items;
  final Catalog catalog;
  const _FeaturedCarousel({required this.items, required this.catalog});

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  final _ctrl = PageController(viewportFraction: 0.86);
  int _page = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final f = widget.items[i];
              return AnimatedPadding(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(
                    horizontal: 6, vertical: _page == i ? 0 : 8),
                child: GestureDetector(
                  onTap: () {
                    final songs = widget.catalog.songs
                        .where((s) => s.category == f.category)
                        .toList();
                    if (songs.isEmpty) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CollectionDetailPage(
                          heroTag: 'feat_${f.id}',
                          title: f.title,
                          subtitle: f.subtitle,
                          cover: f.image,
                          colorValue: 0xFFFF6B9D,
                          songs: songs,
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'feat_${f.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: f.image,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              decoration: const BoxDecoration(
                                gradient: AppColors.brandGradient,
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
                                  Colors.black.withOpacity(0.75),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  f.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  f.subtitle,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.items.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _page ? AppColors.brand : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ============ MIX (đĩa tròn vinyl ngang) ============

class _MixRow extends StatelessWidget {
  final Catalog catalog;
  const _MixRow({required this.catalog});

  @override
  Widget build(BuildContext context) {
    if (catalog.mixes.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: catalog.mixes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final m = catalog.mixes[i];
          final color = Color(m.colorValue);
          return GestureDetector(
            onTap: () {
              final songs = catalog.songsByIds(m.songIds);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CollectionDetailPage(
                    heroTag: 'mix_${m.id}',
                    title: m.title,
                    subtitle: m.subtitle,
                    cover: m.image,
                    colorValue: m.colorValue,
                    songs: songs,
                    fallbackIcon: Icons.album_rounded,
                  ),
                ),
              );
            },
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'mix_${m.id}',
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Color(0xFF222), Colors.black],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                        ),
                        ClipOval(
                          child: SizedBox(
                            width: 78,
                            height: 78,
                            child: CachedNetworkImage(
                              imageUrl: m.image,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(color: color),
                            ),
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    m.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    m.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppPalette.of(context).textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============ SUGGESTED PLAYLISTS (vuông gradient overlay) ============

class _SuggestionRow extends StatelessWidget {
  final Catalog catalog;
  const _SuggestionRow({required this.catalog});

  @override
  Widget build(BuildContext context) {
    if (catalog.suggestions.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: catalog.suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final p = catalog.suggestions[i];
          final color = Color(p.colorValue);
          return GestureDetector(
            onTap: () {
              final songs = catalog.songsByIds(p.songIds);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CollectionDetailPage(
                    heroTag: 'sg_${p.id}',
                    title: p.title,
                    subtitle: p.subtitle,
                    cover: p.image,
                    colorValue: p.colorValue,
                    songs: songs,
                  ),
                ),
              );
            },
            child: Hero(
              tag: 'sg_${p.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 140,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: p.image,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: color),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              color.withOpacity(0.2),
                              Colors.black.withOpacity(0.85),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.headphones_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============ CATEGORY GRID ============

class _CategoryGrid extends StatelessWidget {
  final Catalog catalog;
  const _CategoryGrid({required this.catalog});

  @override
  Widget build(BuildContext context) {
    final cats = catalog.categories;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (_, i) {
        final c = cats[i];
        final color = Color(c.colorValue);
        final count =
            catalog.songs.where((s) => s.category == c.id).length;
        return GestureDetector(
          onTap: () {
            final songs = catalog.songs
                .where((s) => s.category == c.id)
                .toList();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CollectionDetailPage(
                  heroTag: 'cat_${c.id}',
                  title: c.name,
                  subtitle: '$count bài hát',
                  colorValue: c.colorValue,
                  songs: songs,
                  fallbackIcon: Icons.category_rounded,
                ),
              ),
            );
          },
          child: Hero(
            tag: 'cat_${c.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withOpacity(0.4)],
                      ),
                    ),
                  ),
                  // họa tiết note xoay
                  Positioned(
                    right: -12,
                    bottom: -12,
                    child: Transform.rotate(
                      angle: pi / 6,
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 80,
                        color: Colors.white.withOpacity(0.18),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          c.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '$count bài',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============ RANKING (Top 5 với số to + bar visual) ============

class _RankingList extends StatelessWidget {
  final Catalog catalog;
  const _RankingList({required this.catalog});

  @override
  Widget build(BuildContext context) {
    final sorted = [...catalog.songs]
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    final top = sorted.take(5).toList();
    final maxCount = top.isEmpty ? 1 : top.first.playCount;
    final palette = AppPalette.of(context);
    final library = context.watch<LibraryRepository>();
    final audio = context.watch<AudioPlayerService>();

    return Column(
      children: [
        for (var i = 0; i < top.length; i++)
          _RankingTile(
            rank: i + 1,
            song: top[i],
            ratio: top[i].playCount / maxCount,
            isFavorite: library.isFavorite(top[i].id),
            playing: audio.currentSong?.id == top[i].id,
            palette: palette,
            onTap: () async {
              await audio.playSongAt(sorted, i);
              if (!context.mounted) return;
              Navigator.push(context, NowPlayingPage.route());
            },
            onFavorite: () => library.toggleFavorite(top[i]),
          ),
      ],
    );
  }
}

class _RankingTile extends StatelessWidget {
  final int rank;
  final SongModel song;
  final double ratio;
  final bool isFavorite;
  final bool playing;
  final AppPalette palette;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _RankingTile({
    required this.rank,
    required this.song,
    required this.ratio,
    required this.isFavorite,
    required this.playing,
    required this.palette,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = switch (rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => palette.textFaint,
    };
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: rankColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 50,
                height: 50,
                child: song.cover == null
                    ? Container(
                        color: Color(song.colorValue ?? 0xFF1ED760),
                        child:
                            const Icon(Icons.music_note, color: Colors.white),
                      )
                    : CachedNetworkImage(
                        imageUrl: song.cover!,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: playing ? AppColors.brand : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${song.artist} • ${_compact(song.playCount)} lượt nghe',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: palette.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0, 1),
                      minHeight: 3,
                      backgroundColor: palette.subtleFill,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.brand),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onFavorite,
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.redAccent : palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ============ ALBUMS (cover vuông + glow) ============

class _AlbumRow extends StatelessWidget {
  final Catalog catalog;
  const _AlbumRow({required this.catalog});

  @override
  Widget build(BuildContext context) {
    if (catalog.albums.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: catalog.albums.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final a = catalog.albums[i];
          final color = Color(a.colorValue);
          return GestureDetector(
            onTap: () {
              final songs = catalog.songsByIds(a.songIds);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CollectionDetailPage(
                    heroTag: 'al_${a.id}',
                    title: a.title,
                    subtitle:
                        '${a.artist}${a.year != null ? ' • ${a.year}' : ''}',
                    cover: a.cover,
                    colorValue: a.colorValue,
                    songs: songs,
                    fallbackIcon: Icons.album_rounded,
                  ),
                ),
              );
            },
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'al_${a.id}',
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: a.cover,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(color: color),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    a.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    a.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppPalette.of(context).textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
