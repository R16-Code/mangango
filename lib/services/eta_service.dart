// lib/services/eta_service.dart
//
// ETA (OpenRouteService) dengan fallback Haversine + cache Hive.
// - Default mode: "driving-car"; on-demand: "foot-walking"
// - Cache TTL default: 30 menit
// - API key diambil dari --dart-define=ORS_KEY=... (jangan hardcode)
//
// Contoh pakai (detail page):
// final svc = EtaService();
// final res = await svc.getEta(
//   userLat: uLat, userLon: uLon,
//   placeLat: pLat, placeLon: pLon,
//   mode: 'driving-car', // atau 'foot-walking'
// );
//
// Tampilkan: 'ETA ${res.durationMin} mnt • ${res.distanceKm.toStringAsFixed(1)} km'
// Jika res.isFallback == true, berarti hasil estimasi dari Haversine (bukan ORS).
//
// Catatan penting:
// - ORS butuh urutan koordinat lon,lat (bukan lat,lon).
// - Pastikan Hive box 'cache' sudah dibuka di awal aplikasi.
// - Hindari spam request: lakukan debouncing di UI jika perlu.

import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

class EtaResult {
  final String mode;        // 'driving-car' atau 'foot-walking'
  final double distanceKm;  // kilometer
  final int durationMin;    // menit
  final bool fromCache;     // true jika data diambil dari cache
  final bool isFallback;    // true jika hasil dari estimasi Haversine (ORS gagal)

  const EtaResult({
    required this.mode,
    required this.distanceKm,
    required this.durationMin,
    required this.fromCache,
    required this.isFallback,
  });

  @override
  String toString() =>
      'EtaResult(mode=$mode, distanceKm=$distanceKm, durationMin=$durationMin, '
      'fromCache=$fromCache, isFallback=$isFallback)';
}

class EtaService {
  // Jangan hardcode; gunakan --dart-define saat run/build:
  // flutter run --dart-define=ORS_KEY=YOUR_KEY_HERE
  // flutter build apk --dart-define=ORS_KEY=YOUR_KEY_HERE
  final String apiKey;

  // Box cache bersama (sudah digunakan oleh currency_service)
  final Box _cacheBox = Hive.box('cache');

  EtaService({String? apiKeyOverride})
      : apiKey = apiKeyOverride ??
            const String.fromEnvironment('ORS_KEY', defaultValue: '');

  /// Ambil ETA berbasis rute nyata menggunakan OpenRouteService.
  ///
  /// [mode] salah satu: 'driving-car' (default) atau 'foot-walking'.
  /// [cacheTtl] TTL cache; default 30 menit sesuai kesepakatan.
  Future<EtaResult> getEta({
    required double userLat,
    required double userLon,
    required double placeLat,
    required double placeLon,
    String mode = 'driving-car',
    Duration cacheTtl = const Duration(minutes: 30),
  }) async {
    // Validasi minimum
    if (!_isValidCoord(userLat, userLon) || !_isValidCoord(placeLat, placeLon)) {
      return _fallbackHaversine(
        userLat: userLat,
        userLon: userLon,
        placeLat: placeLat,
        placeLon: placeLon,
        mode: mode,
        markFromCache: false,
      );
    }

    // Key cache: bulatkan 3 desimal agar tidak meledak
    final key = _cacheKey(
      mode: mode,
      userLat: userLat,
      userLon: userLon,
      placeLat: placeLat,
      placeLon: placeLon,
    );

    // 1) Cek cache
    final cached = _cacheBox.get(key);
    if (cached is Map) {
      final ts = cached['ts'];
      if (ts is DateTime &&
          DateTime.now().difference(ts) <= cacheTtl &&
          cached['d'] is num &&
          cached['t'] is num) {
        return EtaResult(
          mode: mode,
          distanceKm: (cached['d'] as num).toDouble(),
          durationMin: (cached['t'] as num).toInt(),
          fromCache: true,
          isFallback: cached['fb'] == true,
        );
      }
    }

    // 2) Coba panggil ORS (butuh API key)
    if (apiKey.isNotEmpty) {
      final url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/$mode'
        '?api_key=$apiKey'
        '&start=${_fmt(place: false, lon: userLon)},${_fmt(place: true, lat: userLat)}'
        '&end=${_fmt(place: false, lon: placeLon)},${_fmt(place: true, lat: placeLat)}',
      );

      try {
        final resp = await http.get(url);
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          final features = (data['features'] as List?) ?? const [];
          if (features.isNotEmpty) {
            final props = (features.first as Map)['properties'] as Map;
            final summary = props['summary'] as Map;
            final distanceKm = (summary['distance'] as num).toDouble() / 1000.0; // meter -> km
            final durationMin = ((summary['duration'] as num).toDouble() / 60.0).round();

            final result = EtaResult(
              mode: mode,
              distanceKm: distanceKm,
              durationMin: durationMin,
              fromCache: false,
              isFallback: false,
            );

            // Simpan ke cache
            _cacheBox.put(key, {
              'd': result.distanceKm,
              't': result.durationMin,
              'ts': DateTime.now(),
              'fb': false,
            });

            return result;
          }
        }
      } catch (_) {
        // Diabaikan; akan fallback
      }
    }

    // 3) Fallback Haversine (tanpa ORS / error ORS / tanpa apiKey)
    final fallback = _fallbackHaversine(
      userLat: userLat,
      userLon: userLon,
      placeLat: placeLat,
      placeLon: placeLon,
      mode: mode,
      markFromCache: false,
    );

    // Simpan fallback juga (agar UI tetap cepat pada percobaan berikut)
    _cacheBox.put(key, {
      'd': fallback.distanceKm,
      't': fallback.durationMin,
      'ts': DateTime.now(),
      'fb': true,
    });

    return fallback;
  }

  // =======================
  // Util internal
  // =======================

  bool _isValidCoord(double lat, double lon) {
    if (lat.isNaN || lon.isNaN) return false;
    if (lat == 0.0 && lon == 0.0) return false;
    if (lat < -90 || lat > 90) return false;
    if (lon < -180 || lon > 180) return false;
    return true;
  }

  String _cacheKey({
    required String mode,
    required double userLat,
    required double userLon,
    required double placeLat,
    required double placeLon,
  }) {
    String r(double v) => v.toStringAsFixed(3); // 3 desimal
    return 'eta:$mode:${r(userLat)},${r(userLon)}->${r(placeLat)},${r(placeLon)}';
  }

  /// Format helper untuk menjaga konsistensi pemakaian lat/lon di URL.
  /// ORS menggunakan start=lon,lat & end=lon,lat
  String _fmt({bool place = false, double? lat, double? lon}) {
    // hanya untuk readable, sebenarnya tidak perlu conditional 'place'
    if (lat != null) return lat.toString();
    if (lon != null) return lon.toString();
    return '';
  }

  EtaResult _fallbackHaversine({
    required double userLat,
    required double userLon,
    required double placeLat,
    required double placeLon,
    required String mode,
    required bool markFromCache,
  }) {
    final distKm = _haversine(userLat, userLon, placeLat, placeLon);
    // Kecepatan asumsi konservatif untuk estimasi kasar
    final double kmPerHour = (mode == 'foot-walking') ? 5.0 : 25.0;
    final estMinutes = math.max(1, (distKm / kmPerHour * 60.0).round());

    return EtaResult(
      mode: mode,
      distanceKm: distKm,
      durationMin: estMinutes,
      fromCache: markFromCache,
      isFallback: true,
    );
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // km
    final dLat = _deg(lat2 - lat1);
    final dLon = _deg(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg(lat1)) *
            math.cos(_deg(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _deg(double d) => d * (math.pi / 180.0);
}
