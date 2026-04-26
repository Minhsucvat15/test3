import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/services/auth_service.dart';
import '../auth/login_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final library = context.watch<LibraryRepository>();
    if (user == null) {
      return const Center(child: Text('Chưa đăng nhập'));
    }

    final hash = (user.avatarSeed ?? user.email)
        .codeUnits
        .fold<int>(0, (a, b) => a + b);
    final hue = (hash * 47) % 360;
    final color =
        HSLColor.fromAHSL(1, hue.toDouble(), 0.6, 0.55).toColor();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 110,
            height: 110,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Text(
              user.displayName.isEmpty
                  ? '?'
                  : user.displayName[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            user.displayName,
            style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            user.email,
            style: TextStyle(color: AppPalette.of(context).textMuted),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Tham gia ${prettyDate(user.createdAt)}',
            style: TextStyle(
                color: AppPalette.of(context).textFaint, fontSize: 12),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Yêu thích',
                value: library.favoriteIds.length.toString(),
                icon: Icons.favorite_rounded,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Playlists',
                value: library.playlists.length.toString(),
                icon: Icons.queue_music_rounded,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Đã nghe',
                value: library.recentIds.length.toString(),
                icon: Icons.history_rounded,
                color: AppColors.brandAlt,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: 'Chỉnh sửa hồ sơ',
          icon: Icons.edit_rounded,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfilePage()),
          ),
        ),
        const SizedBox(height: 10),
        PrimaryButton(
          label: 'Đăng xuất',
          icon: Icons.logout_rounded,
          secondary: true,
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Đăng xuất?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Huỷ'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            );
            if (ok != true) return;
            await context.read<AuthService>().logout();
            await context.read<LibraryRepository>().bind(null);
            if (!context.mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                settings: const RouteSettings(name: LoginPage.routeName),
                builder: (_) => const LoginPage(),
              ),
              (_) => false,
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: palette.subtleFill,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: palette.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
