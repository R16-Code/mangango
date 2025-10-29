import 'package:hive/hive.dart';

part 'pengingat_makan.g.dart'; // File ini akan digenerate

// Adaptor typeId 3: PengingatMakan
@HiveType(typeId: 3)
class PengingatMakan extends HiveObject {
  // Pengaturan jam pengingat dalam format List<String> "HH:MM"
  @HiveField(0)
  List<String> times; 

  PengingatMakan({
    required this.times,
  });
}
