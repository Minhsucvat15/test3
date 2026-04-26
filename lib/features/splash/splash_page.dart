import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_logo.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/catalog_service.dart';
import '../../data/services/settings_service.dart';
import '../../data/services/audio_player_service.dart';
import '../auth/login_page.dart';
import '../home/home_shell.dart';

class SplashPage extends StatefulWidget {
  static const routeName = '/splash';
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthService>();
    final settings = context.read<AppSettings>();
    final library = context.read<LibraryRepository>();
    final audio = context.read<AudioPlayerService>();
    final catalogSvc = context.read<CatalogService>();

    await Future.wait([
      auth.bootstrap(),
      settings.load(),
    ]);

    final catalog = await catalogSvc.loadCatalog();
    if (!mounted) return;

    // Lưu catalog vào provider qua Provider.value-based holder
    context.read<CatalogHolder>().set(catalog);

    audio.onPlayed = (s) => library.pushRecent(s);

    await library.bind(auth.currentUser?.id);

    if (auth.currentUser != null && settings.autoPlayOnStart) {
      await audio.restoreLastSession(catalog.songs);
    }

    if (!mounted) return;
    final goLogin = auth.currentUser == null;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        settings: RouteSettings(
          name: goLogin ? LoginPage.routeName : HomeShell.routeName,
        ),
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, a, __) => FadeTransition(
          opacity: a,
          child: goLogin ? const LoginPage() : const HomeShell(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: palette.backgroundGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AnimatedLogo(size: 140),
              const SizedBox(height: 28),
              const Text(
                'GoodMusic',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Âm nhạc cho mọi cảm xúc',
                style: TextStyle(color: palette.textMuted),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Holder đơn giản giữ catalog đã load để các trang khác dùng.
class CatalogHolder extends ChangeNotifier {
  Catalog? _catalog;
  Catalog? get catalog => _catalog;
  void set(Catalog c) {
    _catalog = c;
    notifyListeners();
  }
}
