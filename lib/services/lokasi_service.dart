import 'package:geolocator/geolocator.dart';

class LokasiService {
  Future<(Position?, String)> getCurrentPosition() async {
    // Pastikan layanan lokasi aktif
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return (null, "service_off");
    }

    // Cek akses
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Minta izin
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return (null, "denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Jika user memilih "Don't ask again"
      return (null, "denied_forever");
    }

    // Jika izin ok, ambil posisi
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return (pos, "ok");
    } catch (_) {
      // Jika gagal ambil posisi karena error teknis
      return (null, "denied");
    }
  }
}
