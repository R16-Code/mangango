import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

import 'package:mangango/models/tempat.dart';
import 'package:mangango/utils/haversine.dart';

class TempatService {
  final Box<Tempat> _tempatBox = Hive.box<Tempat>('places');

  static const String _hasSeededKey = 'hasSeededPlaces';
  static const String _seedHashKey = 'placesSeedHashV1';

  Future<String> _computeAssetHash() async {
    final jsonStr = await rootBundle.loadString('assets/data/seed_places.json');
    final bytes = utf8.encode(jsonStr);
    return md5.convert(bytes).toString();
  }

  Future<bool> hasSeeded() async {
    final settings = Hive.box('settings');
    return settings.get(_hasSeededKey, defaultValue: false) as bool;
  }

  // panggil seed
  Future<void> _doSeedFromJson() async {
    await _tempatBox.clear(); // hapus data lama

    final jsonStr = await rootBundle.loadString('assets/data/seed_places.json');
    final List list = json.decode(jsonStr) as List;

    for (final m in list) {
      final t = Tempat.fromJson(Map<String, dynamic>.from(m as Map));
      await _tempatBox.put(t.id, t);
    }
  }

  // seed ulang 
  // jika json berubah
  Future<void> reseedIfJsonChanged() async {
    final settings = Hive.box('settings');

    final currentHash = await _computeAssetHash();
    final savedHash = settings.get(_seedHashKey) as String?;

    if (savedHash == null || savedHash != currentHash) {
      await _doSeedFromJson();
      await settings.put(_seedHashKey, currentHash);
      await settings.put(_hasSeededKey, true);
    }
  }

  Future<void> seedPlacesFromJson() async {
    await reseedIfJsonChanged();
  }

  Future<void> forceReseed() async {
    final settings = Hive.box('settings');
    await _doSeedFromJson();
    final newHash = await _computeAssetHash();
    await settings.put(_seedHashKey, newHash);
    await settings.put(_hasSeededKey, true);
  }

  List<Tempat> getAll() => _tempatBox.values.toList();

  List<Tempat> searchFilterSort({
    required Position? userPos,
    String? searchKeyword,
    double minRating = 0,
    double maxDistanceKm = 9999,
    double? fallbackLat,
    double? fallbackLon,
  }) {
    var list = getAll();

    // Hitung jarak
    final useLat = userPos?.latitude ?? fallbackLat;
    final useLon = userPos?.longitude ?? fallbackLon;
    
    if (useLat != null && useLon != null) {
      for (final t in list) {
        t.distanceKm = haversineDistanceKm(useLat, useLon, t.latitude, t.longitude);
      }
    } else {
      for (final t in list) {
        t.distanceKm = 0;
      }
    }

    // Filter keyword
    if (searchKeyword != null && searchKeyword.trim().isNotEmpty) {
      final q = searchKeyword.toLowerCase().trim();
      list = list.where((t) =>
        t.nama.toLowerCase().contains(q) || t.alamat.toLowerCase().contains(q)
      ).toList();
    }

    // Filter rating & jarak
    list = list.where((t) {
      final dist = t.distanceKm ?? 0;
      return t.rating >= minRating && dist <= maxDistanceKm;
    }).toList();

    // Sort jarak terdekat
    list.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    return list;
  }

  List<Tempat> getSortedPlaces({
    required Position? userPos,
    String? searchKeyword,
    double minRating = 0,
    double maxDistanceKm = 9999,
    double? fallbackLat,
    double? fallbackLon,
  }) =>
      searchFilterSort(
        userPos: userPos,
        searchKeyword: searchKeyword,
        minRating: minRating,
        maxDistanceKm: maxDistanceKm,
        fallbackLat: fallbackLat,
        fallbackLon: fallbackLon,
      );
}
