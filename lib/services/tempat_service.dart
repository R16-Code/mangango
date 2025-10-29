import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mangan_go/models/tempat.dart';
import 'package:mangan_go/utils/haversine.dart';

class TempatService {
  final Box<Tempat> _tempatBox = Hive.box<Tempat>('places');
  static const String _placesKey = 'hasSeededPlaces';

  /// Cek apakah seeding places sudah dilakukan
  Future<bool> hasSeeded() async {
    final settingBox = Hive.box('settings');
    return settingBox.get(_placesKey, defaultValue: false) as bool;
  }

  /// Seed data tempat dari assets JSON ke Hive (sekali saja)
  Future<void> seedPlacesFromJson() async {
    if (await hasSeeded()) return;

    final jsonStr = await rootBundle.loadString('assets/data/seed_places.json');
    final List list = json.decode(jsonStr) as List;

    for (final m in list) {
      final t = Tempat.fromJson(Map<String, dynamic>.from(m as Map));
      await _tempatBox.put(t.id, t);
    }

    final settingBox = Hive.box('settings');
    await settingBox.put(_placesKey, true);
  }

  /// Ambil semua tempat dari Hive
  List<Tempat> getAll() => _tempatBox.values.toList();

  /// Cari + filter + sort (berdasarkan jarak terdekat).
  ///
  /// - Jika [userPos] TIDAK null → jarak dihitung terhadap posisi user.
  /// - Jika [userPos] null dan [fallbackLat]/[fallbackLon] tersedia → jarak dihitung terhadap fallback.
  /// - Jika semuanya null → jarak diset 0 (tidak ideal, tapi tetap aman).
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
      // fallback terakhir: tidak ada posisi sama sekali
      for (final t in list) {
        t.distanceKm = 0;
      }
    }

    // 2) Filter keyword (nama/alamat)
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

  /// Alias untuk kompatibilitas kode lama (jika masih ada pemanggilan getSortedPlaces)
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
