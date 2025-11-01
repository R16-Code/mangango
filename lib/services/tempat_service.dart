import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

import 'package:mangan_go/models/tempat.dart';
import 'package:mangan_go/utils/haversine.dart';

class TempatService {
  final Box<Tempat> _tempatBox = Hive.box<Tempat>('places');

  // Kunci di box 'settings'
  static const String _hasSeededKey = 'hasSeededPlaces';
  static const String _seedHashKey = 'placesSeedHashV1'; // versi schema hash

  /// ========= UTIL HASH JSON ASSET =========
  Future<String> _computeAssetHash() async {
    final jsonStr = await rootBundle.loadString('assets/data/seed_places.json');
    final bytes = utf8.encode(jsonStr);
    return md5.convert(bytes).toString(); // hash pendek, cukup untuk invalidasi
  }

  /// ========= KOMPAT: masih ada yang manggil ini =========
  Future<bool> hasSeeded() async {
    final settings = Hive.box('settings');
    // tetap kembalikan flag lama untuk kompatibilitas, tapi real behavior pakai hash
    return settings.get(_hasSeededKey, defaultValue: false) as bool;
  }

  /// ========= SEED UTAMA (dipanggil saat hash beda / paksa reseed) =========
  Future<void> _doSeedFromJson() async {
    // kosongkan supaya data lama tidak nyangkut
    await _tempatBox.clear();

    final jsonStr = await rootBundle.loadString('assets/data/seed_places.json');
    final List list = json.decode(jsonStr) as List;

    for (final m in list) {
      final t = Tempat.fromJson(Map<String, dynamic>.from(m as Map));
      await _tempatBox.put(t.id, t);
    }
  }

  /// ========= RESEED JIKA JSON BERUBAH =========
  Future<void> reseedIfJsonChanged() async {
    final settings = Hive.box('settings');

    final currentHash = await _computeAssetHash();
    final savedHash = settings.get(_seedHashKey) as String?;

    // Kasus 1: belum pernah seed (savedHash null) → seed sekarang
    // Kasus 2: hash berbeda → JSON berubah → seed ulang
    if (savedHash == null || savedHash != currentHash) {
      await _doSeedFromJson();
      await settings.put(_seedHashKey, currentHash);
      await settings.put(_hasSeededKey, true); // pertahankan flag kompat lama
    }
  }

  /// ========= OPSI: SEED LEGACY (tidak dipakai lagi, tapi tetap ada) =========
  /// Panggilan lama ini sekarang cukup mengdelegasikan ke reseedIfJsonChanged()
  Future<void> seedPlacesFromJson() async {
    await reseedIfJsonChanged();
  }

  /// ========= OPSI: PAKSA RESEED (misal tombol hidden untuk dev) =========
  Future<void> forceReseed() async {
    final settings = Hive.box('settings');
    await _doSeedFromJson();
    final newHash = await _computeAssetHash();
    await settings.put(_seedHashKey, newHash);
    await settings.put(_hasSeededKey, true);
  }

  /// ========= API DATA =========
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

    // 1) Hitung jarak
    if (userPos != null) {
      for (final t in list) {
        t.distanceKm = haversineDistanceKm(
          userPos.latitude, userPos.longitude, t.latitude, t.longitude,
        );
      }
    } else if (fallbackLat != null && fallbackLon != null) {
      for (final t in list) {
        t.distanceKm = haversineDistanceKm(
          fallbackLat, fallbackLon, t.latitude, t.longitude,
        );
      }
    } else {
      for (final t in list) {
        t.distanceKm = 0;
      }
    }

    // 2) Filter keyword
    if (searchKeyword != null && searchKeyword.trim().isNotEmpty) {
      final q = searchKeyword.toLowerCase().trim();
      list = list.where((t) =>
        t.nama.toLowerCase().contains(q) || t.alamat.toLowerCase().contains(q)
      ).toList();
    }

    // 3) Filter rating & jarak maksimum
    list = list.where((t) {
      final dist = t.distanceKm ?? 0;
      return t.rating >= minRating && dist <= maxDistanceKm;
    }).toList();

    // 4) Sort jarak terdekat
    list.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    return list;
  }

  // Alias untuk kompatibilitas kode lama
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
