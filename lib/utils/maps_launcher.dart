import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsLauncher {
  static Future<void> openSmart(
    String? rawUrl, {
    double? lat,
    double? lng,
    String? label,
  }) async {
    // Coba URL yang ada
    final trimmed = (rawUrl ?? '').trim();
    if (trimmed.isNotEmpty) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        if (await _tryLaunch(uri, LaunchMode.externalApplication)) return;
        if (await _tryLaunch(uri, LaunchMode.platformDefault)) return;
        if (await _tryLaunch(uri, LaunchMode.inAppBrowserView)) return;
      }
    }

    // Fallback intent geo (Android)
    if (lat != null && lng != null) {
      if (Platform.isAndroid) {
        final geo = _geoUri(lat, lng, label: label);
        if (await _tryLaunch(geo, LaunchMode.externalApplication)) return;
      }

      // Fallback maps menggunakan koordinat
      final web = _webMapsUri(lat: lat, lng: lng);
      if (await _tryLaunch(web, LaunchMode.externalApplication)) return;
      if (await _tryLaunch(web, LaunchMode.platformDefault)) return;
      await _tryLaunch(web, LaunchMode.inAppBrowserView);
      return;
    }

    // Jika tidak ada URL dan tidak ada koordinat
    // buka beranda Google Maps
    final webHome = _webMapsUri();
    if (await _tryLaunch(webHome, LaunchMode.externalApplication)) return;
    if (await _tryLaunch(webHome, LaunchMode.platformDefault)) return;
    await _tryLaunch(webHome, LaunchMode.inAppBrowserView);
  }

  // Paksa buka URL apa pun
  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await _tryLaunch(uri, LaunchMode.externalApplication)) return;
    if (await _tryLaunch(uri, LaunchMode.platformDefault)) return;
    await _tryLaunch(uri, LaunchMode.inAppBrowserView);
  }

  // Buka koordinat saja
  static Future<void> openMap(double latitude, double longitude, {String? label}) async {
    await openSmart(null, lat: latitude, lng: longitude, label: label);
  }

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

  // mengambil nama tempat, lat, long
  static Uri _geoUri(double lat, double lng, {String? label}) {
    final hasLabel = label != null && label.trim().isNotEmpty;
    final q = hasLabel ? Uri.encodeComponent(label.trim()) : null;
    final path = '$lat,$lng';
    final geo = q == null ? 'geo:$path' : 'geo:$path?q=$q';
    return Uri.parse(geo);
  }

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