import 'package:intl/intl.dart';

/// Kelas service untuk logika konversi waktu sederhana.
/// Service ini akan dipanggil oleh:
/// - `lib/screens/detail_tempat_page.dart`
class TimeService {
  // Format waktu yang diinginkan (Contoh: 14:30 (29/10))
  final DateFormat _timeFormat = DateFormat('HH:mm (dd/MM)');

  /// Mendapatkan waktu saat ini dalam zona waktu yang ditentukan.
  /// Jogja (tempat aplikasi ini) dianggap sebagai WIB (GMT+7).
  String getCurrentTimeInZone(String zone) {
    // Dapatkan waktu UTC dan konversi ke WIB (GMT+7) sebagai basis
    // Kita asumsikan perangkat pengguna sudah di Waktu Indonesia Barat
    DateTime nowWIB = DateTime.now();

    switch (zone.toUpperCase()) {
      case 'WIB':
        // Waktu lokal (GMT+7)
        return _timeFormat.format(nowWIB);
      case 'WITA':
        // WITA = WIB + 1 jam (GMT+8)
        return _timeFormat.format(nowWIB.add(const Duration(hours: 1)));
      case 'WIT':
        // WIT = WIB + 2 jam (GMT+9)
        return _timeFormat.format(nowWIB.add(const Duration(hours: 2)));
      case 'LONDON':
        // London = GMT+1 (BST saat summer) / GMT+0 (GMT saat winter)
        // Kita pakai GMT+1 (WIB - 6 jam) sebagai contoh
        return _timeFormat.format(nowWIB.subtract(const Duration(hours: 6)));
      default:
        return _timeFormat.format(nowWIB);
    }
  }

  /// Mengembalikan daftar string waktu yang sudah dikonversi
  Map<String, String> getConvertedTimes() {
    return {
      'WIB': getCurrentTimeInZone('WIB'),
      'WITA': getCurrentTimeInZone('WITA'),
      'WIT': getCurrentTimeInZone('WIT'),
      'LONDON': getCurrentTimeInZone('LONDON'),
    };
  }
}

