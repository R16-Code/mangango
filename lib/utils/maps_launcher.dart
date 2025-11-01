// lib/utils/maps_launcher.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Util pembuka Google Maps / URL dengan fallback yang kuat.
/// Urutan:
/// 1) Coba URL yang disediakan (http/https) apa adanya
/// 2) Fallback: intent geo: (khususnya Android, akurat ke koordinat)
/// 3) Fallback: web (https Google Maps) pakai koordinat / query
class MapsLauncher {
  /// Entry point utama: coba buka [rawUrl] dulu; kalau gagal, pakai [lat],[lng] sebagai fallback.
  static Future<void> openSmart(
    String? rawUrl, {
    double? lat,
    double? lng,
    String? label,
  }) async {
    // 1) Coba URL apa adanya dulu (kalau ada dan valid)
    final trimmed = (rawUrl ?? '').trim();
    if (trimmed.isNotEmpty) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        if (await _tryLaunch(uri, LaunchMode.externalApplication)) return;
        if (await _tryLaunch(uri, LaunchMode.platformDefault)) return;
        if (await _tryLaunch(uri, LaunchMode.inAppBrowserView)) return;
        // kalau URL gagal, lanjut fallback koordinat/web
      }
    }

    // 2) Fallback kuat: intent geo: (Android)
    if (lat != null && lng != null) {
      if (Platform.isAndroid) {
        final geo = _geoUri(lat, lng, label: label);
        if (await _tryLaunch(geo, LaunchMode.externalApplication)) return;
      }

      // 3) Fallback web: https Google Maps pakai koordinat (pasti kebuka)
      final web = _webMapsUri(lat: lat, lng: lng);
      if (await _tryLaunch(web, LaunchMode.externalApplication)) return;
      if (await _tryLaunch(web, LaunchMode.platformDefault)) return;
      await _tryLaunch(web, LaunchMode.inAppBrowserView);
      return;
    }

    // 4) Jika tidak ada URL dan tidak ada koordinat → buka beranda Google Maps
    final webHome = _webMapsUri();
    if (await _tryLaunch(webHome, LaunchMode.externalApplication)) return;
    if (await _tryLaunch(webHome, LaunchMode.platformDefault)) return;
    await _tryLaunch(webHome, LaunchMode.inAppBrowserView);
  }

  /// Buka URL apa pun secara eksplisit (kalau kamu ingin memaksa URL saja).
  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await _tryLaunch(uri, LaunchMode.externalApplication)) return;
    if (await _tryLaunch(uri, LaunchMode.platformDefault)) return;
    await _tryLaunch(uri, LaunchMode.inAppBrowserView);
  }

  /// Buka koordinat saja (tanpa URL).
  static Future<void> openMap(double latitude, double longitude, {String? label}) async {
    await openSmart(null, lat: latitude, lng: longitude, label: label);
  }

  // ----------------- Helpers -----------------

  static Future<bool> _tryLaunch(Uri uri, LaunchMode mode) async {
    try {
      final ok = await launchUrl(uri, mode: mode);
      if (!ok && kDebugMode) {
        debugPrint('launchUrl gagal: $uri (mode=$mode)');
      }
      return ok;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('launchUrl exception: $uri (mode=$mode) -> $e');
      }
      return false;
    }
  }

  // geo:-7.78,110.40?q=Warung%20Makan (Android akan arahkan ke app Maps)
  static Uri _geoUri(double lat, double lng, {String? label}) {
    final hasLabel = label != null && label.trim().isNotEmpty;
    final q = hasLabel ? Uri.encodeComponent(label.trim()) : null;
    final path = '$lat,$lng';
    final geo = q == null ? 'geo:$path' : 'geo:$path?q=$q';
    return Uri.parse(geo);
  }

  // Web fallback:
  // - jika query diberikan → https://www.google.com/maps/search/?api=1&query=<query>
  // - jika lat/lng diberikan → https://www.google.com/maps/search/?api=1&query=lat,lng
  // - kalau tidak ada keduanya → https://www.google.com/maps
  static Uri _webMapsUri({String? query, double? lat, double? lng}) {
    if (query != null && query.trim().isNotEmpty) {
      return Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': query,
      });
    }
    if (lat != null && lng != null) {
      return Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': '$lat,$lng',
      });
    }
    return Uri.https('www.google.com', '/maps');
  }
}
