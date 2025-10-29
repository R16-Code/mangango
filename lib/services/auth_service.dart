import 'package:hive/hive.dart';
import 'package:mangan_go/models/pengguna.dart';
import 'package:mangan_go/services/session_service.dart';
import 'package:mangan_go/utils/security.dart';

class AuthService {
  final SessionService _sessionService = SessionService();
  final Box<Pengguna> _userBox = Hive.box<Pengguna>('users');

  /// Cari user by username (case-insensitive)
  Pengguna? getUserByUsername(String username) {
    final uname = username.trim().toLowerCase();
    for (final u in _userBox.values) {
      if (u.username.trim().toLowerCase() == uname) return u;
    }
    return null;
  }

  /// Register user baru
  /// return `null` jika sukses; string pesan error jika gagal.
  Future<String?> register({
    required String username,
    required String password,
  }) async {
    final uname = username.trim();
    if (uname.isEmpty || password.isEmpty) {
      return 'Username dan password tidak boleh kosong.';
    }

    // Cek duplikasi
    final existing = getUserByUsername(uname);
    if (existing != null) {
      return 'Username sudah terdaftar.';
    }

    // Hash password
    final salt = SecurityUtils.generateSalt();
    final hash = SecurityUtils.hashPassword(password, salt);

    // Buat ID sederhana (pakai waktu + random)
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    final user = Pengguna(
      id: id,
      username: uname,
      hashedPassword: hash,
      salt: salt,
      // reminderTimes default ada di model
    );

    await _userBox.put(id, user);
    // Opsional: langsung login setelah register
    await _sessionService.setLoggedIn(userId: id);
    return null;
  }

  /// Login
  /// return `null` jika sukses; string pesan error jika gagal.
  Future<String?> login({
    required String username,
    required String password,
  }) async {
    final user = getUserByUsername(username);
    if (user == null) return 'Username tidak ditemukan.';

    final isValid = SecurityUtils.verifyPassword(
      password,
      user.salt,
      user.hashedPassword,
    );

    if (!isValid) return 'Password salah.';

    await _sessionService.setLoggedIn(userId: user.id);
    return null;
  }

  /// Logout (hanya hapus session, tidak menghapus user)
  Future<void> logout() async {
    await _sessionService.logout();
  }
}
