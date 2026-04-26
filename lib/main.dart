import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'core/theme/theme_controller.dart';
import 'data/repositories/library_repository.dart';
import 'data/services/audio_player_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/catalog_service.dart';
import 'data/services/settings_service.dart';
import 'data/services/storage_service.dart';
import 'features/splash/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase. Nếu lỗi (chưa cấu hình platform native) thì bỏ qua,
  // app vẫn chạy ở chế độ local.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (kDebugMode) debugPrint('Firebase init skipped: $e');
  }


  final storage = StorageService();
  final auth = AuthService(storage);
  final library = LibraryRepository(storage);
  final settings = AppSettings();
  final theme = ThemeController();
  final audio = AudioPlayerService();
  final catalog = CatalogService();
  final catalogHolder = CatalogHolder();

  // Theme load sớm để splash đúng theme
  theme.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: library),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: theme),
        ChangeNotifierProvider.value(value: audio),
        ChangeNotifierProvider.value(value: catalogHolder),
        Provider<StorageService>.value(value: storage),
        Provider<CatalogService>.value(value: catalog),
      ],
      child: const MyApp(),
    ),
  );
}
