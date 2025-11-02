import 'package:hive/hive.dart';

class SessionService {
  static const String _boxName = 'session';
  static const String _keyUserId = 'userId';
  static const String _keyLoginTime = 'loginTime';
  static const Duration sessionDuration = Duration(hours: 1);

  Future<Box<dynamic>> _getSessionBox() async {
    return await Hive.openBox<dynamic>(_boxName);
  }

  Future<void> setLoggedIn({required String userId}) async {
    final box = await _getSessionBox();
    await box.putAll({
      _keyUserId: userId,
      _keyLoginTime: DateTime.now().toIso8601String(),
    });
  }

  Future<String?> getLoggedInUserId() async {
    final box = await _getSessionBox();
    final userId = box.get(_keyUserId);
    final loginTimeStr = box.get(_keyLoginTime);
    
    // Cek session,
    // apakah ada?
    if (userId == null || loginTimeStr == null) return null;
    
    // Cek session,
    // expired?
    final loginTime = DateTime.parse(loginTimeStr);
    final now = DateTime.now();
    if (now.difference(loginTime) > sessionDuration) {
      await logout();
      return null;
    }
    
    return userId as String;
  }

  Future<void> logout() async {
    final box = await _getSessionBox();
    await box.clear(); // hapus sesi
  }
}