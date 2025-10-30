import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mangan_go/services/notif_service.dart';

import 'app.dart';
import 'models/pengguna.dart';
import 'models/tempat.dart';
import 'models/cache_kurs.dart';
import 'models/pengingat_makan.dart';
import 'services/tempat_service.dart';

Future<void> _initHiveAndSeed() async {
  await Hive.initFlutter();
  Hive.registerAdapter(PenggunaAdapter());
  Hive.registerAdapter(TempatAdapter());
  Hive.registerAdapter(CacheKursAdapter());
  Hive.registerAdapter(PengingatMakanAdapter());

  await Hive.openBox<Pengguna>('users');
  await Hive.openBox<Tempat>('places');
  await Hive.openBox<CacheKurs>('cache');
  await Hive.openBox<PengingatMakan>('reminders');
  await Hive.openBox('settings');

  final tempatService = TempatService();
  if (!await tempatService.hasSeeded()) {
    await tempatService.seedPlacesFromJson();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initHiveAndSeed();
  await NotifService().initialize(); // ⬅️ Harus sebelum runApp
  runApp(const App());
}

