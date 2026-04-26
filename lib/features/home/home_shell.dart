import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../library/library_page.dart';
import '../profile/profile_page.dart';
import '../search/search_page.dart';
import '../settings/settings_page.dart';
import 'home_page.dart';

class HomeShell extends StatefulWidget {
  static const routeName = '/home';
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    HomePage(),
    SearchPage(),
    LibraryPage(),
    ProfilePage(),
    SettingsPage(),
  ];

  static const _items = [
    (Icons.home_rounded, 'Trang chủ'),
    (Icons.search_rounded, 'Tìm kiếm'),
    (Icons.library_music_rounded, 'Thư viện'),
    (Icons.person_rounded, 'Hồ sơ'),
    (Icons.settings_rounded, 'Cài đặt'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: palette.backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (c, a) =>
                FadeTransition(opacity: a, child: c),
            child: KeyedSubtree(
              key: ValueKey(_index),
              child: _pages[_index],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: dark ? const Color(0xFF11141B) : Colors.white,
        indicatorColor: AppColors.brand.withOpacity(0.18),
        height: 64,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final (icon, label) in _items)
            NavigationDestination(icon: Icon(icon), label: label),
        ],
      ),
    );
  }
}
