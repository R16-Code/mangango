import 'package:hive/hive.dart';
import 'package:mangan_go/models/pengguna.dart';
import 'package:mangan_go/services/session_service.dart';
import 'package:mangan_go/utils/security.dart';

class AuthService {
  final SessionService _sessionService = SessionService();
  final Box<Pengguna> _userBox = Hive.box<Pengguna>('users');

  /// Mencari apakah username sudah terdaftar
  Pengguna? getUserByUsername(String username) {
    return _userBox.values.cast<Pengguna?>().firstWhere(
          (user) => user?.username.toLowerCase() == username.toLowerCase(),
          orElse: () => null,
        );
  }

  /// Melakukan registrasi pengguna baru
  Future<bool> register(String username, String password) async {
    // Cek apakah username sudah ada
    if (getUserByUsername(username) != null) {
      return false; // Registrasi gagal karena username sudah terdaftar
    }

    // 1. Generate Salt
    final String salt = SecurityUtils.generateSalt();
    // 2. Hash Password
    final String hashedPassword = SecurityUtils.hashPassword(password, salt);
    
    // 3. Buat objek Pengguna
    final newUserId = DateTime.now().millisecondsSinceEpoch.toString(); // ID sederhana
    final newPengguna = Pengguna(
      id: newUserId,
      username: username,
      hashedPassword: hashedPassword,
      salt: salt,
      reminderTimes: const ['07:00', '12:00', '19:00'], // Default
    );

    // 4. Simpan ke Hive
    await _userBox.put(newUserId, newPengguna);
    
    // 5. Langsung set session setelah register
    await _sessionService.setLoggedIn(userId: newUserId);

    return true; // Registrasi berhasil
  }

  /// Melakukan proses login
  Future<String?> login(String username, String password) async {
    final Pengguna? user = getUserByUsername(username);

    if (user == null) {
      return 'Username tidak ditemukan.';
    }

    // 1. Verifikasi Password
    final bool isValid = SecurityUtils.verifyPassword(
      password, 
      user.hashedPassword, 
      user.salt,
    );

    if (isValid) {
      // 2. Jika valid, set session
      await _sessionService.setLoggedIn(userId: user.id);
      return null; // Login berhasil (mengembalikan null untuk sukses)
    } else {
      return 'Password salah.';
    }
  }

  /// Melakukan logout
  Future<void> logout() async {
    await _sessionService.logout();
  }
}
