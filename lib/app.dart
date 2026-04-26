import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routes/route_tracker.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/mini_player.dart';
import 'features/auth/forgot_password_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/home/home_shell.dart';
import 'features/player/now_playing_page.dart';
import 'features/splash/splash_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    return MaterialApp(
      title: 'GoodMusic',
      debugShowCheckedModeBanner: false,
      themeMode: theme.mode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      navigatorObservers: [AppRouteTracker.instance],
      // Splash là route đầu tiên - đặt name để observer biết.
      onGenerateRoute: (settings) {
        if (settings.name == '/' || settings.name == null) {
          return MaterialPageRoute(
            settings: const RouteSettings(name: SplashPage.routeName),
            builder: (_) => const SplashPage(),
          );
        }
        return null;
      },
      builder: (context, child) {
        return _GlobalMiniPlayerOverlay(child: child ?? const SizedBox());
      },
    );
  }
}

class _GlobalMiniPlayerOverlay extends StatelessWidget {
  final Widget child;
  const _GlobalMiniPlayerOverlay({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _GlobalMiniPlayer(),
        ),
      ],
    );
  }
}

class _GlobalMiniPlayer extends StatelessWidget {
  const _GlobalMiniPlayer();

  static const _hideOn = {
    NowPlayingPage.routeName,
    SplashPage.routeName,
    LoginPage.routeName,
    RegisterPage.routeName,
    ForgotPasswordPage.routeName,
  };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: AppRouteTracker.instance.currentName,
      builder: (_, name, __) {
        if (name != null && _hideOn.contains(name)) {
          return const SizedBox.shrink();
        }
        // HomeShell có bottom nav 64px → nâng mini player lên cao hơn.
        final hasBottomNav = name == HomeShell.routeName;
        final bottomPad = hasBottomNav ? 72.0 : 12.0;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPad),
            child: const Material(
              color: Colors.transparent,
              child: MiniPlayer(),
            ),
          ),
        );
      },
    );
  }
}
