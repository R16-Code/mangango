import 'package:hive/hive.dart';

part 'tempat.g.dart'; // File ini digenerate oleh build_runner

/// Adaptor typeId 1: Tempat
@HiveType(typeId: 1)
class Tempat extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String nama;

  @HiveField(2)
  String alamat;

  @HiveField(3)
  double latitude;

  @HiveField(4)
  double longitude;

  @HiveField(5)
  String kisaranHarga;

  /// Simpan rating sebagai double (mis. 4.6)
  @HiveField(6)
  double rating;

  /// Jam buka dalam format "HH:mm"
  @HiveField(7)
  String jamBuka;

  /// Jam tutup dalam format "HH:mm"
  @HiveField(8)
  String jamTutup;

  /// URL Google Maps (opsional)
  @HiveField(9)
  String urlMaps;

  /// Field non-persisten: jarak dari posisi user (Tidak ada anotasi HiveField,
  /// jadi TIDAK ikut diserialisasi oleh Hive).
  double? distanceKm;

  Tempat({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    required this.kisaranHarga,
    required this.rating,
    required this.jamBuka,
    required this.jamTutup,
    this.urlMaps = '',
    this.distanceKm,
  });

  /// Factory untuk memuat dari JSON (assets seed)
  factory Tempat.fromJson(Map<String, dynamic> json) {
    return Tempat(
      id: json['id'] as int,
      nama: json['nama'] as String,
      alamat: json['alamat'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      kisaranHarga: json['kisaranHarga'] as String,
      rating: (json['rating'] as num).toDouble(),
      jamBuka: json['jamBuka'] as String,
      jamTutup: json['jamTutup'] as String,
      urlMaps: (json['urlMaps'] as String?) ?? '',
    );
  }
}
