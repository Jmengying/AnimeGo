import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class LocalAuthService {
  static const String _usersKey = 'registered_users';
  static const String _currentUserKey = 'current_user';

  Map<String, dynamic>? _currentUser;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_currentUserKey);
    if (userStr != null) {
      _currentUser = json.decode(userStr);
    }

    // Create default admin account if no users exist
    final usersStr = prefs.getString(_usersKey) ?? '{}';
    final users = Map<String, dynamic>.from(json.decode(usersStr));
    if (users.isEmpty) {
      users['admin@animego.com'] = {
        'email': 'admin@animego.com',
        'password': 'admin123',
        'username': '管理员',
        'isAdmin': true,
        'createdAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_usersKey, json.encode(users));
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String username) async {
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString(_usersKey) ?? '{}';
    final users = Map<String, dynamic>.from(json.decode(usersStr));

    if (users.containsKey(email)) {
      throw Exception('该邮箱已被注册');
    }

    users[email] = {
      'email': email,
      'password': password,
      'username': username,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_usersKey, json.encode(users));

    _currentUser = users[email];
    await prefs.setString(_currentUserKey, json.encode(_currentUser));

    return _currentUser!;
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString(_usersKey) ?? '{}';
    final users = Map<String, dynamic>.from(json.decode(usersStr));

    if (!users.containsKey(email)) {
      throw Exception('用户不存在');
    }

    final user = users[email] as Map<String, dynamic>;
    if (user['password'] != password) {
      throw Exception('密码错误');
    }

    _currentUser = user;
    await prefs.setString(_currentUserKey, json.encode(_currentUser));

    return _currentUser!;
  }

  Future<void> signOut() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  Future<void> updatePassword(String email, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString(_usersKey) ?? '{}';
    final users = Map<String, dynamic>.from(json.decode(usersStr));

    if (users.containsKey(email)) {
      (users[email] as Map<String, dynamic>)['password'] = newPassword;
      await prefs.setString(_usersKey, json.encode(users));
    }
  }

  Future<void> updateAvatar(String email, File imageFile) async {
    // Save image to app documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final avatarDir = Directory('${appDir.path}/avatars');
    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }
    final ext = imageFile.path.split('.').last;
    final savedFile = await imageFile.copy('${avatarDir.path}/$email.$ext');

    // Update user map with avatar path
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString(_usersKey) ?? '{}';
    final users = Map<String, dynamic>.from(json.decode(usersStr));

    if (users.containsKey(email)) {
      (users[email] as Map<String, dynamic>)['avatar'] = savedFile.path;
      await prefs.setString(_usersKey, json.encode(users));
      if (_currentUser != null && _currentUser!['email'] == email) {
        _currentUser!['avatar'] = savedFile.path;
        await prefs.setString(_currentUserKey, json.encode(_currentUser));
      }
    }
  }
}
