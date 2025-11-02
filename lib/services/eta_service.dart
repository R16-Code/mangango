// lib/services/eta_service.dart
//
// ETA (OpenRouteService) dengan fallback Haversine + cache Hive.
// - Default mode: "driving-car"; on-demand: "foot-walking"
// - Cache TTL default: 30 menit
// - API key diambil dari --dart-define=ORS_KEY=... 

import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:mangango/utils/haversine.dart';

class EtaResult {
  final String mode;        // 'driving-car' atau 'foot-walking'
  final double distanceKm;  // kilometer
  final int durationMin;    // menit
  final bool fromCache;     // true jika data diambil dari cache
  final bool isFallback;    // true jika hasil dari estimasi Haversine (API gagal)

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
  // MapBox API Key
  final String apiKey;

  // Box cache khusus ETA
  final Box _cacheBox = Hive.box('eta_cache');

  EtaService({String? apiKeyOverride})
      : apiKey = apiKeyOverride ??
            const String.fromEnvironment('ORS_KEY', defaultValue: '');

  /// Ambil ETA berbasis rute nyata menggunakan OpenRouteService.
  ///
  /// [mode] salah satu: 'driving-car' (default) atau 'foot-walking'.
  /// [cacheTtl] TTL cache; default 30 menit.
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

    // Key cache: bulatkan 3 desimal
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

    // 2) Coba panggil OpenRouteService (butuh API key)
    if (apiKey.isNotEmpty) {
      final url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/$mode'
        '?api_key=$apiKey'
        '&start=${userLon},${userLat}'  // PERHATIAN: lon,lat (bukan lat,lon)
        '&end=${placeLon},${placeLat}'  // PERHATIAN: lon,lat (bukan lat,lon)
      );

      try {
        final resp = await http.get(url);
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          final features = (data['features'] as List?) ?? const [];
          
          if (features.isNotEmpty) {
            final route = features.first as Map;
            final properties = route['properties'] as Map;
            final summary = properties['summary'] as Map;
            
            final distance = (summary['distance'] as num).toDouble(); // dalam meter
            final duration = (summary['duration'] as num).toDouble(); // dalam detik
            
            final distanceKm = distance / 1000.0; // meter -> km
            final durationMin = (duration / 60.0).round(); // detik -> menit

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
        } else {
          print('ORS Error: ${resp.statusCode} - ${resp.body}');
        }
      } catch (e) {
        print('ORS Exception: $e');
        // Diabaikan; akan fallback
      }
    }

    // 3) Fallback Haversine (tanpa API / error API / tanpa apiKey)
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

  EtaResult _fallbackHaversine({
    required double userLat,
    required double userLon,
    required double placeLat,
    required double placeLon,
    required String mode,
    required bool markFromCache,
  }) {
    final distKm = haversineDistanceKm(userLat, userLon, placeLat, placeLon);
    
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
}