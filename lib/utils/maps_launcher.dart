import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Util sederhana untuk membuka Google Maps / URL.
/// Versi ini kompatibel dengan url_launcher lama (pakai String, bukan Uri).
class MapsLauncher {
  /// Buka URL apa pun (mis. tautan Google Maps)
  static Future<void> openUrl(String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(url); // versi lama: menerima String
      } else {
        if (kDebugMode) {
          debugPrint('MapsLauncher.openUrl: cannot launch $url');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MapsLauncher.openUrl error: $e');
      }
    }
  }

  /// Buka koordinat di Google Maps.
  /// [label] opsional: nama tempat untuk query.
  static Future<void> openMap(double latitude, double longitude, {String? label}) async {
    final q = (label == null || label.trim().isEmpty)
        ? '$latitude,$longitude'
        : Uri.encodeComponent('$label ($latitude,$longitude)');

    final url = 'https://www.google.com/maps/search/?api=1&query=$q';

    try {
      if (await canLaunch(url)) {
        await launch(url); // versi lama: menerima String
      } else {
        if (kDebugMode) {
          debugPrint('MapsLauncher.openMap: cannot launch $url');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MapsLauncher.openMap error: $e');
      }
    }
  }

  static Future<void> launchUrl(String url) => openUrl(url);
  static Future<void> openCoordinates(double latitude, double longitude, [String? label]) =>
      openMap(latitude, longitude, label: label);
}
