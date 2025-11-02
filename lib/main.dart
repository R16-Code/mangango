import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mangango/services/notif_service.dart';

import 'app.dart';
import 'models/pengguna.dart';
import 'models/tempat.dart';
import 'models/cache_kurs.dart';
import 'services/tempat_service.dart';

Future<void> _initHiveAndSeed() async {
  await Hive.initFlutter();
  Hive.registerAdapter(PenggunaAdapter());
  Hive.registerAdapter(TempatAdapter());
  Hive.registerAdapter(CacheKursAdapter());

  await Hive.openBox<Pengguna>('users');
  await Hive.openBox<Tempat>('places');
  await Hive.openBox<CacheKurs>('currency_cache');
  await Hive.openBox('eta_cache');
  await Hive.openBox('settings');

  final tempatService = TempatService();
  await tempatService.reseedIfJsonChanged();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initHiveAndSeed();
  await NotifService().initialize();
  runApp(const App());
}