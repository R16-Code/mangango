import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:mangan_go/models/cache_kurs.dart';

class CurrencyService {
  static const String _apiKey = 'GANTI_DENGAN_API_KEY_ANDA';
  static const String _apiUrl = 'https://v6.exchangerate-api.com/v6/$_apiKey/latest/IDR';
  static const String _boxName = 'cache'; // pakai box 'cache' (CacheKurs)

  Future<Map<String, double>> fetchAndCacheRates() async {
    final box = Hive.box<CacheKurs>(_boxName);

    // Coba baca cache
    Map<String, double> cached = {};
    for (final code in ['USD', 'JPY', 'EUR']) {
      final item = box.get(code);
      if (item != null) cached[code] = item.rate;
    }
    if (cached.length == 3) return cached;

    // Fetch online (optional)
    try {
      if (_apiKey != 'GANTI_DENGAN_API_KEY_ANDA') {
        final resp = await http.get(Uri.parse(_apiUrl));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          final rates = (data['conversion_rates'] as Map).map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
          );
          final now = DateTime.now();
          for (final code in ['USD', 'JPY', 'EUR']) {
            final r = rates[code] ?? 0;
            await box.put(code, CacheKurs(currencyCode: code, rate: r, lastUpdated: now));
          }
          return {'USD': rates['USD'] ?? 0, 'JPY': rates['JPY'] ?? 0, 'EUR': rates['EUR'] ?? 0};
        }
      }
    } catch (_) {}

    // Fallback statis
    final now = DateTime.now();
    final fallback = {'USD': 0.000060, 'JPY': 0.0090, 'EUR': 0.000055};
    for (final e in fallback.entries) {
      await box.put(e.key, CacheKurs(currencyCode: e.key, rate: e.value, lastUpdated: now));
    }
    return fallback;
  }

  Map<String, double> convert(double amountIDR, Map<String, double> rates) {
    return {
      'USD': amountIDR * (rates['USD'] ?? 0),
      'JPY': amountIDR * (rates['JPY'] ?? 0),
      'EUR': amountIDR * (rates['EUR'] ?? 0),
    };
  }
}
