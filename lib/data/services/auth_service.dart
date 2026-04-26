import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/hash.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

/// Auth chạy local: lưu danh sách users vào users.json,
/// session bằng SharedPreferences. Có thể swap sang Firebase Auth
/// bằng cách thay class này (giữ nguyên public API).
class AuthService extends ChangeNotifier {
  AuthService(this._storage);
  final StorageService _storage;

  static const _kSession = 'auth_user_id';

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<List<UserModel>> _readUsers() async {
    final raw = await _storage.readJson('users.json', fallback: <dynamic>[]);
    if (raw is! List) return [];
    return raw
        .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _writeUsers(List<UserModel> users) async {
    await _storage.writeJson(
      'users.json',
      users.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kSession);
    if (id == null) return;
    final users = await _readUsers();
    _currentUser = users.where((u) => u.id == id).cast<UserModel?>().firstWhere(
          (u) => u != null,
          orElse: () => null,
        );
    notifyListeners();
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final users = await _readUsers();
    final exists = users.any((u) => u.email.toLowerCase() == email.toLowerCase());
    if (exists) {
      throw Exception('Email đã tồn tại');
    }
    final user = UserModel(
      id: const Uuid().v4(),
      email: email.trim(),
      displayName: displayName.trim(),
      passwordHash: hashPassword(password),
      avatarSeed: email.trim(),
      createdAt: DateTime.now(),
    );
    users.add(user);
    await _writeUsers(users);
    await _setSession(user);
    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final users = await _readUsers();
    UserModel? user;
    for (final u in users) {
      if (u.email.toLowerCase() == email.toLowerCase()) {
        user = u;
        break;
      }
    }
    if (user == null) throw Exception('Tài khoản không tồn tại');
    if (user.passwordHash != hashPassword(password)) {
      throw Exception('Sai mật khẩu');
    }
    await _setSession(user);
    return user;
  }

  Future<void> _setSession(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSession, user.id);
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSession);
    notifyListeners();
  }

  Future<void> updateProfile({String? displayName, String? avatarSeed}) async {
    final user = _currentUser;
    if (user == null) return;
    final updated = user.copyWith(
      displayName: displayName,
      avatarSeed: avatarSeed,
    );
    final users = await _readUsers();
    final idx = users.indexWhere((u) => u.id == user.id);
    if (idx == -1) return;
    users[idx] = updated;
    await _writeUsers(users);
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');
    if (user.passwordHash != hashPassword(oldPassword)) {
      throw Exception('Mật khẩu cũ không đúng');
    }
    final updated = user.copyWith(passwordHash: hashPassword(newPassword));
    final users = await _readUsers();
    final idx = users.indexWhere((u) => u.id == user.id);
    if (idx == -1) return;
    users[idx] = updated;
    await _writeUsers(users);
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final users = await _readUsers();
    final idx = users.indexWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );
    if (idx == -1) throw Exception('Email không tồn tại');
    users[idx] = users[idx].copyWith(passwordHash: hashPassword(newPassword));
    await _writeUsers(users);
  }

  Future<void> deleteAccount() async {
    final user = _currentUser;
    if (user == null) return;
    final users = await _readUsers();
    users.removeWhere((u) => u.id == user.id);
    await _writeUsers(users);
    await logout();
  }
}
