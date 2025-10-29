import 'package:flutter/material.dart';
import 'package.flutter_local_notifications/flutter_local_notifications.dart';
import 'package.flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package.timezone/timezone.dart' as tz;

/// Kelas service untuk mengelola notifikasi lokal.
/// Service ini akan dipanggil oleh:
/// - `lib/screens/profil_page.dart`
class NotifService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inisialisasi service notifikasi
  Future<void> initialize() async {
    // 1. Pengaturan Android
    // Menggunakan ikon default '@mipmap/ic_launcher'
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. Pengaturan iOS (jika diperlukan nanti)
    // const DarwinInitializationSettings initializationSettingsIOS = ...

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      // iOS: initializationSettingsIOS,
    );

    // Inisialisasi plugin
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // 3. Konfigurasi Timezone (Sangat Penting untuk Penjadwalan)
    await _configureLocalTimezone();
  }

  /// Konfigurasi Timezone Lokal
  Future<void> _configureLocalTimezone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  /// Menjadwalkan notifikasi harian pada jam tertentu
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    await initialize(); // Pastikan selalu terinisialisasi
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mangan_go_channel_id', // ID Channel
          'Mangan Go Channel', // Nama Channel
          channelDescription: 'Channel untuk pengingat makan.',
          importance: Importance.high, // Tampilkan di atas
          priority: Priority.high, // Prioritas tinggi
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Izinkan saat idle
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Ulangi setiap hari pada jam ini
    );
    print('Notifikasi ID $id dijadwalkan pukul $time');
  }

  /// Helper untuk mendapatkan instance TZDateTime berikutnya dari TimeOfDay
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    
    // Jika waktu hari ini sudah lewat, jadwalkan untuk besok
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Membatalkan semua notifikasi
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print('Semua notifikasi dibatalkan.');
  }
}

