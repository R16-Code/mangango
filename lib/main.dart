import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import Models dan Generated Adapters
import 'package:mangan_go/models/pengguna.dart';
import 'package:mangan_go/models/tempat.dart';
import 'package:mangan_go/models/cache_kurs.dart';
import 'package:mangan_go/models/pengingat_makan.dart';

// Placeholder untuk App() dan Router (akan dibuat di langkah berikutnya)
import 'package:mangan_go/app.dart'; 
import 'package:mangan_go/router.dart';

void main() async {
  // Memastikan Flutter Widgets diinisialisasi sebelum menjalankan fungsi
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inisialisasi Hive
  // Menentukan lokasi penyimpanan Hive yang sesuai
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  // 2. Mendaftarkan Hive Adapters
  // **PENTING:** Adaptor ini digenerate oleh build_runner
  Hive.registerAdapter(PenggunaAdapter());
  Hive.registerAdapter(TempatAdapter());
  Hive.registerAdapter(CacheKursAdapter());
  Hive.registerAdapter(PengingatMakanAdapter());

  // 3. Membuka Box Hive yang akan digunakan
  // Box 'users' untuk data pengguna
  await Hive.openBox<Pengguna>('users');
  // Box 'places' untuk data tempat makan (hasil seed dari JSON)
  await Hive.openBox<Tempat>('places');
  // Box 'cache' untuk menyimpan kurs mata uang offline
  await Hive.openBox<CacheKurs>('cache');
  // Box 'reminders' untuk menyimpan pengaturan jam pengingat
  await Hive.openBox<PengingatMakan>('reminders');


  runApp(const App());
}
