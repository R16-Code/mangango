import 'package:hive/hive.dart';

part 'cache_kurs.g.dart'; // File ini akan digenerate

// Adaptor typeId 2: CacheKurs
@HiveType(typeId: 2)
class CacheKurs extends HiveObject {
  // Mata uang yang di-cache (e.g., USD, JPY, EUR)
  @HiveField(0)
  String currencyCode; 

  // Nilai tukar terhadap IDR (1 IDR = X Mata Uang Asing)
  @HiveField(1)
  double rate; 

  // Waktu terakhir data diambil dari API
  @HiveField(2)
  DateTime lastUpdated;

  CacheKurs({
    required this.currencyCode,
    required this.rate,
    required this.lastUpdated,
  });
}
