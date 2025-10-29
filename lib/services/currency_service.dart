import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:mangan_go/models/cache_kurs.dart';

class CurrencyService {
  // Ganti dengan API Key Anda (Contoh: exchangerate-api.com)
  // URL ini adalah contoh dan mungkin perlu disesuaikan
  static const String _apiKey = 'GANTI_DENGAN_API_KEY_ANDA'; // <-- PENTING
  static const String _apiUrl = 'https://v6.exchangerate-api.com/v6/$_apiKey/latest/IDR';
  static const String _boxName = 'currencyCache';

  /// Mengambil kurs dari API atau Cache
  Future<Map<String, double>> fetchAndCacheRates() async {
    final box = await Hive.openBox<CacheKurs>(_boxName);
    CacheKurs? cache = box.get('latest');

    // Cek apakah cache ada dan masih valid (misal: 6 jam)
    if (cache != null &&
        DateTime.now().difference(cache.timestamp).inHours < 6) {
      print('Menggunakan kurs dari Cache Hive.');
      return cache.rates;
    }

    // Jika cache tidak valid, ambil dari API
    print('Mengambil kurs baru dari API...');
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<String, dynamic> ratesData = data['conversion_rates'];

        // Ambil hanya kurs yang kita butuhkan
        final Map<String, double> rates = {
          'USD': (ratesData['USD'] as num).toDouble(),
          'JPY': (ratesData['JPY'] as num).toDouble(),
          'EUR': (ratesData['EUR'] as num).toDouble(),
        };

        // --- PERBAIKAN DI SINI ---
        // Simpan ke cache Hive menggunakan konstruktor yang benar
        final newCache = CacheKurs(
          timestamp: DateTime.now(),
          rates: rates,
        );
        await box.put('latest', newCache);
        // --- AKHIR PERBAIKAN ---

        return rates;
      } else {
        return _getFallbackRates(cache); // Gagal API, gunakan cache lama jika ada
      }
    } catch (e) {
      print('Error fetch API: $e');
      return _getFallbackRates(cache); // Gagal total, gunakan cache lama jika ada
    }
  }

  /// Fallback jika API gagal
  Map<String, double> _getFallbackRates(CacheKurs? oldCache) {
    if (oldCache != null) {
      print('API Gagal. Menggunakan fallback cache lama.');
      return oldCache.rates; // Gunakan cache lama
    }
    // Fallback terakhir jika API gagal DAN cache kosong
    print('API Gagal. Menggunakan fallback data statis.');
    return {
      'USD': 0.000060, // Kurs statis
      'JPY': 0.0090,
      'EUR': 0.000055,
    };
  }

  /// Konversi nilai IDR ke mata uang lain
  Map<String, double> convert(double amountIDR, Map<String, double> rates) {
    return {
      'USD': amountIDR * (rates['USD'] ?? 0),
      'JPY': amountIDR * (rates['JPY'] ?? 0),
      'EUR': amountIDR * (rates['EUR'] ?? 0),
    };
  }
}