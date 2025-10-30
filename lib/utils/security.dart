import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Util keamanan sederhana berbasis SHA-256 + salt.
/// Dibuat sebagai drop-in untuk menggantikan referensi `SecurityUtils`
/// yang dipakai di `auth_service.dart` agar tidak perlu ubah file lain.
class SecurityUtils {
  /// Generate salt acak (default 16 karakter)
  static String generateSalt([int length = 16]) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Hash password dengan format: sha256("$salt:$password")
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifikasi password input terhadap hash tersimpan
  static bool verifyPassword(String inputPassword, String salt, String storedHash) {
    return hashPassword(inputPassword, salt) == storedHash;
  }
}