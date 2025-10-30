import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Layanan notifikasi dengan:
/// - initialize()  : inisialisasi + timezones
/// - requestPermission(): minta izin (Android 13+/iOS)
/// - showSimple()  : notifikasi instan
/// - scheduleDaily(): jadwal harian (berulang)
/// - rescheduleReminders(): cancel lama + buat jadwal baru dari 3 jam
/// - cancelAllNotifications(): matikan semua
class NotifService {
  NotifService._();
  static final NotifService _i = NotifService._();
  factory NotifService() => _i;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Init timezone agar schedule harian akurat
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    _initialized = true;
  }

  /// Minta izin notifikasi (Android 13+ & iOS).
  Future<void> requestPermission() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  AndroidNotificationDetails _androidDetails() => const AndroidNotificationDetails(
        'mangango_daily_channel',
        'Pengingat Harian',
        channelDescription: 'Notifikasi pengingat makan harian',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

  NotificationDetails _details() =>
      NotificationDetails(android: _androidDetails(), iOS: const DarwinNotificationDetails());

  /// Notifikasi instan (tetap dipertahankan untuk kompatibilitas).
  Future<void> showSimple(String title, String body) async {
    await initialize();
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      _details(),
    );
  }

  /// Jadwal notifikasi HARIAN pada jam:menit lokal.
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      next,
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // ulangi harian
      payload: payload,
    );
  }

  /// Buat 3 ID stabil dari userId (String) + index (0..2), supaya mudah cancel.
  List<int> _stableIds(String userId) {
    // hash sederhana tapi stabil
    final base = userId.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    return [base % 1000000, (base + 1) % 1000000, (base + 2) % 1000000];
    // angka < 1.000.000 aman untuk ID
  }

  /// Ulangi jadwal: batalkan 3 notifikasi lama lalu jadwalkan lagi berdasarkan 3 waktu.
  /// times: daftar 3 string 'HH:mm' [pagi, siang, malam]
  Future<void> rescheduleReminders({
    required String userId,
    required List<String> times, // ex: ['07:00','12:00','19:00']
  }) async {
    await initialize();
    await requestPermission();

    final ids = _stableIds(userId);

    // cancel lama
    for (final id in ids) {
      await flutterLocalNotificationsPlugin.cancel(id);
    }

    String label(int idx) => switch (idx) {
      0 => 'Pengingat Sarapan',
      1 => 'Pengingat Makan Siang',
      _ => 'Pengingat Makan Malam',
    };

    String body(int idx) => switch (idx) {
      0 => 'Waktunya sarapan supaya kuat berburu kuliner 🍜',
      1 => 'Jangan lewatkan makan siangmu ✨',
      _ => 'Isi tenaga lagi—malam ini makan apa? 🍽️',
    };

    for (var i = 0; i < times.length && i < 3; i++) {
      final parts = times[i].split(':');
      if (parts.length != 2) continue;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;

      await scheduleDaily(
        id: ids[i],
        hour: h,
        minute: m,
        title: label(i),
        body: body(i),
        payload: i == 0 ? 'pagi' : (i == 1 ? 'siang' : 'malam'),
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
