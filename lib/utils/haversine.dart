import 'package:haversine_distance/haversine_distance.dart';

class HaversineUtils {
  /// Menghitung jarak antara dua koordinat dalam kilometer.
  /// 
  /// [lat1], [lon1]: Koordinat titik 1 (misalnya, lokasi pengguna).
  /// [lat2], [lon2]: Koordinat titik 2 (misalnya, lokasi tempat makan).
  ///
  /// Menggunakan package `haversine_distance`.
  static double calculateDistanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    
    // Konversi ke format GeoCoordinate yang dibutuhkan oleh package
    final startCoordinate = GeoCoordinate(lat1, lon1);
    final endCoordinate = GeoCoordinate(lat2, lon2);

    final haversine = HaversineDistance();

    // Mengembalikan jarak dalam kilometer
    return haversine.haversine(
      startCoordinate,
      endCoordinate,
      Unit.KM,
    );
  }
}
