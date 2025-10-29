import 'package:url_launcher/url_launcher.dart';

/// Kelas utilitas untuk menangani deep-link ke aplikasi peta.
class MapsLauncher {
  /// Membuka Google Maps (atau Apple Maps di iOS) untuk navigasi
  /// ke koordinat [latitude] dan [longitude] yang diberikan.
  ///
  /// File ini dipanggil dari:
  /// - `lib/screens/detail_tempat_page.dart`
  static Future<void> launchMaps(double latitude, double longitude) async {
    // URL Skema universal untuk Google Maps
    final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    
    // (Opsional) Untuk Apple Maps di iOS:
    // final String appleMapsUrl = 'https://maps.apple.com/?q=$latitude,$longitude';

    try {
      final Uri uri = Uri.parse(googleMapsUrl);
      
      // Cek apakah URL bisa dibuka
      if (await canLaunchUrl(uri)) {
        // Buka di aplikasi eksternal (bukan di dalam webview)
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback jika Google Maps tidak terinstal atau gagal
        print('Tidak dapat membuka $googleMapsUrl');
        // Di aplikasi nyata, kita akan menampilkan dialog error
      }
    } catch (e) {
      print('Error saat membuka maps: $e');
    }
  }
}

