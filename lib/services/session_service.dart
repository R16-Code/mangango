import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _currentUserIdKey = 'current_user_id';

  /// Menyimpan status login dan ID pengguna yang sedang aktif.
  Future<void> setLoggedIn({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_currentUserIdKey, userId);
  }

  /// Mengambil status apakah pengguna sedang login.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Mengambil ID pengguna yang sedang login.
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserIdKey);
  }

  /// Melakukan logout: menghapus status login dan ID pengguna.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_currentUserIdKey);
  }
}
