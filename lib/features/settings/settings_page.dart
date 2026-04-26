import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/settings_service.dart';
import '../auth/login_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final settings = context.watch<AppSettings>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        const Text(
          'Cài đặt',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Giao diện',
          children: [
            _ThemeSelector(controller: theme),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Phát nhạc',
          children: [
            SwitchListTile(
              title: const Text('Chất lượng cao'),
              subtitle: const Text('Tốn dung lượng mạng hơn'),
              value: settings.highQuality,
              activeColor: AppColors.brand,
              onChanged: settings.setHighQuality,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Tự phát khi mở app'),
              subtitle: const Text('Tiếp tục bài đang nghe dở'),
              value: settings.autoPlayOnStart,
              activeColor: AppColors.brand,
              onChanged: settings.setAutoPlayOnStart,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Đồng bộ',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cloud_off_rounded),
              title: const Text('Cloud sync (sắp có)'),
              subtitle: const Text(
                'Hiện app đang chạy ở chế độ local. Cấu hình Firebase để bật đồng bộ.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Khác',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_sweep_rounded,
                  color: Colors.orange),
              title: const Text('Xoá bộ nhớ đệm'),
              subtitle: const Text('Xoá ảnh đã cache, không xoá dữ liệu'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã yêu cầu xoá cache ảnh')),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dangerous_rounded,
                  color: Colors.redAccent),
              title: const Text(
                'Xoá tài khoản',
                style: TextStyle(color: Colors.redAccent),
              ),
              subtitle: const Text('Hành động này không thể hoàn tác'),
              onTap: () => _confirmDelete(context),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info_outline_rounded),
              title: Text('Phiên bản'),
              subtitle: Text('GoodMusic 1.0.0'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá tài khoản?'),
        content: const Text(
          'Toàn bộ playlists, yêu thích, lịch sử nghe sẽ mất.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    await context.read<AuthService>().deleteAccount();
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
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: palette.subtleFill,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: palette.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final ThemeController controller;
  const _ThemeSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    final mode = controller.mode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _opt(
              label: 'Tối',
              icon: Icons.dark_mode_rounded,
              active: mode == ThemeMode.dark,
              onTap: () => controller.setMode(ThemeMode.dark),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _opt(
              label: 'Sáng',
              icon: Icons.light_mode_rounded,
              active: mode == ThemeMode.light,
              onTap: () => controller.setMode(ThemeMode.light),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _opt(
              label: 'Hệ thống',
              icon: Icons.brightness_auto_rounded,
              active: mode == ThemeMode.system,
              onTap: () => controller.setMode(ThemeMode.system),
            ),
          ),
        ],
      ),
    );
  }

  Widget _opt({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final palette = AppPalette.of(context);
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: active
                  ? AppColors.brand.withOpacity(0.18)
                  : palette.subtleFill,
              border: Border.all(
                color: active ? AppColors.brand : palette.border,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: active ? AppColors.brand : palette.textMuted),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? AppColors.brand : palette.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
