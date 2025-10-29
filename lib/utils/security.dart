import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class SecurityUtils {
  // --- PBKDF2 Hashing Function ---
  // Algoritma hashing yang aman untuk password

  /// Membuat string salt acak dengan panjang 16 byte.
  static String generateSalt([int length = 16]) {
    final rand = Random.secure();
    final List<int> salt = List.generate(length, (_) => rand.nextInt(256));
    return base64Encode(salt);
  }

  /// Melakukan hashing PBKDF2 pada password.
  /// Iterasi 100.000 adalah standar yang baik untuk PBKDF2.
  static String hashPassword(String password, String salt) {
    final saltBytes = base64Decode(salt);
    final passwordBytes = utf8.encode(password);
    
    // Parameter PBKDF2
    const int keyLength = 64; // Panjang kunci yang dihasilkan
    const int iterations = 100000; // Jumlah iterasi (harus tinggi)

    final key = pbkdf2.call(
      passwordBytes, 
      saltBytes, 
      keyLength, 
      iterations, 
      sha256,
    );
    
    return base64Encode(key);
  }

  /// Verifikasi password dengan membandingkan hash baru dengan hash yang tersimpan.
  static bool verifyPassword(String password, String storedHash, String storedSalt) {
    final newHash = hashPassword(password, storedSalt);
    return newHash == storedHash;
  }
}
