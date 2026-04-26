import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  bool _highQuality = true;
  bool _autoPlayOnStart = false;
  String _language = 'vi';

  bool get highQuality => _highQuality;
  bool get autoPlayOnStart => _autoPlayOnStart;
  String get language => _language;

  static const _kHQ = 'settings_hq';
  static const _kAuto = 'settings_auto';
  static const _kLang = 'settings_lang';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _highQuality = p.getBool(_kHQ) ?? true;
    _autoPlayOnStart = p.getBool(_kAuto) ?? false;
    _language = p.getString(_kLang) ?? 'vi';
    notifyListeners();
  }

  Future<void> setHighQuality(bool v) async {
    _highQuality = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kHQ, v);
  }

  Future<void> setAutoPlayOnStart(bool v) async {
    _autoPlayOnStart = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kAuto, v);
  }

  Future<void> setLanguage(String code) async {
    _language = code;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, code);
  }
}
