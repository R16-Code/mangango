import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:mangango/models/cache_kurs.dart';

class CurrencyService {
  static const String _apiKey = '241c8c10e48eb75a83bcbcb5';
  static const String _apiUrl = 'https://v6.exchangerate-api.com/v6/$_apiKey/latest/IDR';
  static const String _boxName = 'currency_cache';

  Future<Map<String, double>> fetchAndCacheRates() async {
    final box = Hive.box<CacheKurs>(_boxName);

    // Cek cache
    final now = DateTime.now();
    Map<String, double> cached = {};
    bool cacheValid = true;

    for (final code in ['USD', 'JPY', 'EUR']) {
      final item = box.get(code);
      if (item != null) {
        // Cek apakah cache masih fresh
        if (now.difference(item.lastUpdated).inHours < 24) {
          cached[code] = item.rate;
        } else {
          cacheValid = false;
          break;
        }
      } else {
        cacheValid = false;
        break;
      }
    }

    if (cacheValid && cached.length == 3) {
      return cached;
    }

    // Fetch online
    try {
      if (_apiKey != '241c8c10e48eb75a83bcbcb5') {
        final resp = await http.get(Uri.parse(_apiUrl));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          final rates = (data['conversion_rates'] as Map).map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
          );
          
          final now = DateTime.now();
          final result = <String, double>{};
          
          for (final code in ['USD', 'JPY', 'EUR']) {
            final rate = rates[code] ?? 0;
            await box.put(code, CacheKurs(
              currencyCode: code, 
              rate: rate, 
              lastUpdated: now
            ));
            result[code] = rate;
          }
          
          return result;
        }
      }
    } catch (e) {
      print('Currency API Error: $e');
    }
    // Fallback: coba pakai cache yang ada 
    //(meski expired)
    if (cached.isNotEmpty) {
      return cached;
    }

    // fallback statis
    final fallback = {'USD': 0.000064, 'JPY': 0.0095, 'EUR': 0.000059};
    final nowFallback = DateTime.now();
    for (final entry in fallback.entries) {
      await box.put(entry.key, CacheKurs(
        currencyCode: entry.key, 
        rate: entry.value, 
        lastUpdated: nowFallback
      ));
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