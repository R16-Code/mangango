import 'package:intl/intl.dart';

class TimeService {
  final DateFormat _timeFormat = DateFormat('HH:mm (dd/MM)');

  // Mendapatkan waktu saat ini (GMT+7)
  String getCurrentTimeInZone(String zone) {
    DateTime nowWIB = DateTime.now();

    switch (zone.toUpperCase()) {
      case 'WIB':
        return _timeFormat.format(nowWIB);
      case 'WITA':
        return _timeFormat.format(nowWIB.add(const Duration(hours: 1)));
      case 'WIT':
        return _timeFormat.format(nowWIB.add(const Duration(hours: 2)));
      case 'LONDON':
        return _timeFormat.format(nowWIB.subtract(const Duration(hours: 6)));
      default:
        return _timeFormat.format(nowWIB);
    }
  }

  // Kembalikan waktu yang dikonversi
  Map<String, String> getConvertedTimes() {
    return {
      'WIB': getCurrentTimeInZone('WIB'),
      'WITA': getCurrentTimeInZone('WITA'),
      'WIT': getCurrentTimeInZone('WIT'),
      'LONDON': getCurrentTimeInZone('LONDON'),
    };
  }
}

