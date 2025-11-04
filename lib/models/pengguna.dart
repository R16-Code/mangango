import 'package:hive/hive.dart';

part 'pengguna.g.dart'; // File ini akan digenerate oleh build_runner

@HiveType(typeId: 0)
class Pengguna extends HiveObject {
  @HiveField(0)
  String id; 

  @HiveField(1)
  String username;

  @HiveField(2)
  String hashedPassword; 
  
  @HiveField(3)
  String salt;

  @HiveField(4)
  List<String> reminderTimes; 

  Pengguna({
    required this.id,
    required this.username,
    required this.hashedPassword,
    required this.salt,
    this.reminderTimes = const ['07:00', '12:00', '19:00'], // Default
  });
}
