import 'package:geolocator/geolocator.dart';

class LokasiService {
  /// Mengambil lokasi user.
  /// Return: (Position? pos, String status)
  ///
  /// status:
  /// "ok"              -> lokasi berhasil diambil
  /// "service_off"     -> layanan lokasi di device mati
  /// "denied"          -> user menolak permission sekali
  /// "denied_forever"  -> user blok permanen
  Future<(Position?, String)> getCurrentPosition() async {
    // 1. Pastikan layanan lokasi aktif
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return (null, "service_off");
    }

    // 2. Cek permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Minta izin
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return (null, "denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // User memilih "Don't ask again"
      return (null, "denied_forever");
    }

    // 3. Jika izin ok, ambil posisi
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return (pos, "ok");
    } catch (_) {
      // Kalau gagal ambil posisi karena error teknis
      return (null, "denied");
    }
  }
}
