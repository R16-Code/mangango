import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import 'package:geolocator/geolocator.dart'; // Untuk tipe Position
import 'package:mangan_go/models/tempat.dart';
import 'package:mangan_go/utils/haversine.dart';

class TempatService {
  final Box<Tempat> _tempatBox = Hive.box<Tempat>('places');
  static const String _placesKey = 'hasSeededPlaces'; // Kunci untuk SharedPreferences/Hive

  /// Mengecek apakah data tempat makan sudah pernah di-seed ke Hive.
  Future<bool> hasSeeded() async {
    // Kita bisa menggunakan box sederhana atau SharedPreferences, kita gunakan box saja
    final settingBox = await Hive.openBox('settings');
    return settingBox.get(_placesKey, defaultValue: false) as bool;
  }

  /// Memuat data dari JSON dan menyimpannya ke Hive.
  Future<void> seedPlacesFromJson(BuildContext context) async {
    if (await hasSeeded()) {
      return; // Sudah pernah di-seed, lewati.
    }

    print('Seeding data tempat makan...');
    try {
      // Baca file JSON dari assets
      final String response = await rootBundle.loadString('assets/data/seed_places.json');
      final List<dynamic> data = json.decode(response);

      // Konversi data JSON ke model Tempat dan simpan ke Hive
      for (var item in data) {
        final tempat = Tempat.fromJson(item as Map<String, dynamic>);
        // Menggunakan id sebagai kunci
        await _tempatBox.put(tempat.id.toString(), tempat);
      }

      // Tandai bahwa proses seeding sudah selesai
      final settingBox = await Hive.openBox('settings');
      await settingBox.put(_placesKey, true);
      print('Seeding berhasil: ${_tempatBox.length} tempat tersimpan.');

    } catch (e) {
      print('Gagal melakukan seeding data: $e');
      throw Exception('Gagal memuat data tempat. Pastikan seed_places.json valid.');
    }
  }

  /// Mendapatkan semua tempat makan dari Hive.
  List<Tempat> getAllPlaces() {
    return _tempatBox.values.toList().cast<Tempat>();
  }

  /// Mendapatkan data tempat makan berdasarkan ID.
  Tempat? getPlaceById(int id) {
    return _tempatBox.get(id.toString());
  }

  // --- Logika Pencarian, Filter, dan Sorting ---

  /// Mendapatkan daftar tempat makan yang sudah diurutkan berdasarkan jarak.
  List<Tempat> getSortedPlaces(Position userLocation, {
    String? searchKeyword,
    double minRating = 0.0,
    double maxDistanceKm = double.infinity,
  }) {
    List<Tempat> filteredList = getAllPlaces();

    // 1. Hitung Jarak dan Tambahkan ke Objek (Temporary property)
    for (var tempat in filteredList) {
      tempat.distanceKm = HaversineUtils.calculateDistanceKm(
        userLocation.latitude,
        userLocation.longitude,
        tempat.latitude,
        tempat.longitude,
      );
    }
    
    // 2. Filter (Search Keyword)
    if (searchKeyword != null && searchKeyword.isNotEmpty) {
      final keywordLower = searchKeyword.toLowerCase();
      filteredList = filteredList.where((tempat) {
        return tempat.nama.toLowerCase().contains(keywordLower) || 
               tempat.alamat.toLowerCase().contains(keywordLower);
      }).toList();
    }

    // 3. Filter (Rating dan Jarak)
    filteredList = filteredList.where((tempat) {
      final meetsRating = tempat.rating >= minRating;
      final meetsDistance = tempat.distanceKm <= maxDistanceKm;
      return meetsRating && meetsDistance;
    }).toList();


    // 4. Sorting (Wajib berdasarkan jarak terdekat)
    filteredList.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return filteredList;
  }

  Future getTempatTerdekat(Position position) async {}
}
