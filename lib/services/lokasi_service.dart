import 'package:geolocator/geolocator.dart';

class LokasiService {
  /// Meminta Izin Lokasi dan mengembalikan status izin.
  Future<LocationPermission> checkAndRequestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek apakah layanan lokasi aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Jika tidak aktif, minta pengguna untuk mengaktifkannya
      // Tidak bisa force open settings, jadi kita return status
      return Future.error('Layanan lokasi tidak aktif.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Izin ditolak
        return Future.error('Izin lokasi ditolak. Aplikasi tidak dapat menghitung jarak.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Izin ditolak permanen
      return Future.error('Izin lokasi ditolak permanen. Harap aktifkan secara manual di pengaturan.');
    }

    return permission;
  }

  /// Mendapatkan posisi (koordinat) pengguna saat ini.
  /// Memastikan izin sudah diberikan sebelum memanggil fungsi ini.
  Future<Position> getCurrentLocation() async {
    final permission = await checkAndRequestPermission();

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      // Jika masih ada masalah izin, kembalikan posisi dummy (0,0) sebagai fallback
      // atau throw error. Untuk UI yang stabil, kita berikan fallback, tapi log error.
      print('ERROR: Lokasi tidak tersedia. Menggunakan koordinat dummy.');
      return Position(
        latitude: -7.7956, // Contoh koordinat pusat Jogja
        longitude: 110.3695,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    }
    
    // Posisi akurat
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
