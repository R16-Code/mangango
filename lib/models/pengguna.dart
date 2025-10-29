import 'package:hive/hive.dart';

part 'pengguna.g.dart'; // File ini akan digenerate oleh build_runner

// Adaptor typeId 0: Pengguna
@HiveType(typeId: 0)
class Pengguna extends HiveObject {
  // ID unik pengguna, bisa berupa UUID atau ID yang diincrement
  @HiveField(0)
  String id; 

  @HiveField(1)
  String username;

  // Password yang sudah di-hash (PBKDF2)
  @HiveField(2)
  String hashedPassword; 
  
  // Salt yang digunakan untuk hashing
  @HiveField(3)
  String salt;

  // Pengaturan pengingat makan (dalam format HH:MM)
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
