import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class SecurityUtils {
  // Generate salt acak (16 karakter)
  static String generateSalt([int length = 16]) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  // Hash password dengan 
  // sha256("$salt:$password")
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verifikasi password
  static bool verifyPassword(String inputPassword, String salt, String storedHash) {
    return hashPassword(inputPassword, salt) == storedHash;
  }
}