import 'package:hive/hive.dart';

part 'cache_kurs.g.dart';

@HiveType(typeId: 2)
class CacheKurs extends HiveObject {
  @HiveField(0)
  String currencyCode; 

  @HiveField(1)
  double rate; 

  @HiveField(2)
  DateTime lastUpdated;

  CacheKurs({
    required this.currencyCode,
    required this.rate,
    required this.lastUpdated,
  });
}
