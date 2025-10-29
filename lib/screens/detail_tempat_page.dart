import 'package:flutter/material.dart';
import 'package:mangan_go/models/tempat.dart';
import 'package:mangan_go/utils/maps_launcher.dart';
import 'package:mangan_go/services/currency_service.dart';

class DetailTempatPage extends StatefulWidget {
  final Tempat tempat;
  const DetailTempatPage({super.key, required this.tempat});

  @override
  State<DetailTempatPage> createState() => _DetailTempatPageState();
}

class _DetailTempatPageState extends State<DetailTempatPage> {
  final CurrencyService _currency = CurrencyService();

  Map<String, double>? _rates; // {'USD': x, 'EUR': y, 'JPY': z}
  bool _loadingRates = true;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    final rates = await _currency.fetchAndCacheRates();
    if (!mounted) return;
    setState(() {
      _rates = rates;
      _loadingRates = false;
    });
  }

  // =======================
  // ====== UTIL TIME ======
  // =======================

  DateTime _parseWibToday(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.elementAt(0)) ?? 0;
    final m = int.tryParse(parts.elementAt(1)) ?? 0;

    final nowLocal = DateTime.now();
    // WIB = UTC+7 → representasikan sebagai UTC (jam WIB - 7)
    final baseUtc = DateTime.utc(nowLocal.year, nowLocal.month, nowLocal.day, 0, 0);
    return baseUtc.add(Duration(hours: h - 7, minutes: m));
  }

  String _fmtHHmm(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  // WIB (as UTC) → offset target (jam dari UTC)
  String _fromWIBtoOffset(String hhmm, int targetOffsetHours) {
    final asUtc = _parseWibToday(hhmm);
    final atTarget = asUtc.add(Duration(hours: targetOffsetHours));
    return _fmtHHmm(atTarget);
  }

  bool _isLondonBST(DateTime dayUtc) {
    DateTime lastSunday(int year, int month) {
      final firstOfNext = (month == 12)
          ? DateTime.utc(year + 1, 1, 1)
          : DateTime.utc(year, month + 1, 1);
      final lastOfMonth = firstOfNext.subtract(const Duration(days: 1));
      // weekday: Mon=1..Sun=7 → mundur sampai Minggu
      return lastOfMonth.subtract(Duration(days: lastOfMonth.weekday % 7));
    }

    final y = dayUtc.year;
    final start = lastSunday(y, 3).add(const Duration(hours: 1));   // 01:00 UTC (BST mulai)
    final end   = lastSunday(y, 10).add(const Duration(hours: 1));  // 01:00 UTC (BST selesai)
    return !dayUtc.isBefore(start) && !dayUtc.isAfter(end);
  }

  (String hhmm, String label) _fromWIBtoLondon(String hhmm) {
    final todayUtc = DateTime.now().toUtc();
    final isBST = _isLondonBST(todayUtc);
    final offset = isBST ? 1 : 0; // UTC+1 saat BST, UTC+0 saat GMT
    final converted = _fromWIBtoOffset(hhmm, offset);
    return (converted, isBST ? 'BST' : 'GMT');
  }

  // ==========================
  // ====== UTIL CURRENCY =====
  // ==========================

  // Parse "Rp20.000 - Rp50.000" / "20000-50000" / "Rp 25.000 s/d 60.000"
  (int? minIdr, int? maxIdr) _parseIdrRange(String text) {
    final digits = RegExp(r'(\d+)');
    final cleaned = text.replaceAll('.', '').replaceAll(',', '');
    final nums = digits.allMatches(cleaned).map((m) => m.group(1)!).toList();
    if (nums.isEmpty) return (null, null);
    if (nums.length == 1) {
      final v = int.tryParse(nums[0]);
      return (v, v);
    }
    final a = int.tryParse(nums[0]);
    final b = int.tryParse(nums[1]);
    if (a == null || b == null) return (null, null);
    final minv = a < b ? a : b;
    final maxv = a < b ? b : a;
    return (minv, maxv);
  }

  String _fmtMoney(num value, {String symbol = '', int fraction = 2}) {
    return '$symbol${value.toStringAsFixed(fraction)}';
  }

  String _toForeignRange(
    int? minIdr,
    int? maxIdr,
    Map<String, double> rates,
    String code, {
    String symbol = '',
    int fraction = 2,
  }) {
    if (minIdr == null && maxIdr == null) return 'Tidak diketahui';
    double conv(int v) => v * (rates[code] ?? 0.0);
    if (minIdr != null && maxIdr != null && minIdr != maxIdr) {
      return '${_fmtMoney(conv(minIdr), symbol: symbol, fraction: fraction)}'
             ' - ${_fmtMoney(conv(maxIdr), symbol: symbol, fraction: fraction)}';
    }
    final v = (minIdr ?? maxIdr)!;
    return _fmtMoney(conv(v), symbol: symbol, fraction: fraction);
  }

  // ======================
  // ====== MAP OPEN  =====
  // ======================

  bool _looksLikeBrokenShortLink(String url) {
    final u = url.toLowerCase();
    return u.contains('maps.app.goo.gl') || u.contains('goo.gl/maps');
    // kedua domain itu sering 404 Dynamic Link jika tidak valid
  }

  void _openMaps(Tempat t) {
    if (t.urlMaps.isNotEmpty && !_looksLikeBrokenShortLink(t.urlMaps)) {
      MapsLauncher.openUrl(t.urlMaps);
    } else {
      MapsLauncher.openMap(t.latitude, t.longitude, label: t.nama);
    }
  }

  // ======================
  // ====== UI HELPERS ====
  // ======================

  Widget _rowInfo({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 15),
                children: [
                  TextSpan(text: '$label\n', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tempat;

    // ===== Waktu operasional =====
    final (bLondon, bLabel) = _fromWIBtoLondon(t.jamBuka);
    final (tLondon, tLabel) = _fromWIBtoLondon(t.jamTutup);
    final bukaWITA = _fromWIBtoOffset(t.jamBuka, 8); // UTC+8
    final tutupWITA = _fromWIBtoOffset(t.jamTutup, 8);
    final bukaWIT = _fromWIBtoOffset(t.jamBuka, 9);  // UTC+9
    final tutupWIT = _fromWIBtoOffset(t.jamTutup, 9);

    // ===== Harga (IDR + konversi via API/CurrencyService) =====
    final (minIdr, maxIdr) = _parseIdrRange(t.kisaranHarga);
    final idrText = t.kisaranHarga.isNotEmpty ? t.kisaranHarga : 'Tidak diketahui';

    String hargaForeignBlock() {
      if (_loadingRates || _rates == null) {
        return 'Memuat kurs...';
      }
      final rates = _rates!;
      final usd = _toForeignRange(minIdr, maxIdr, rates, 'USD', symbol: '\$', fraction: 2);
      final eur = _toForeignRange(minIdr, maxIdr, rates, 'EUR', symbol: '€', fraction: 2);
      final jpy = _toForeignRange(minIdr, maxIdr, rates, 'JPY', symbol: '¥', fraction: 0);
      return 'USD: $usd\nEUR: $eur\nJPY: $jpy';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tempat'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t.nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text('${t.rating}'),
            ],
          ),
          const SizedBox(height: 12),

          _rowInfo(icon: Icons.location_on, label: 'Alamat', value: t.alamat),

          // Harga + konversi
          _rowInfo(
            icon: Icons.attach_money,
            label: 'Kisaran Harga',
            value: '$idrText\n${hargaForeignBlock()}',
          ),

          // Waktu operasional
          _rowInfo(
            icon: Icons.access_time,
            label: 'Jam Operasional',
            value: 'WIB : ${t.jamBuka}–${t.jamTutup}'
                '\nWITA: $bukaWITA–$tutupWITA'
                '\nWIT : $bukaWIT–$tutupWIT'
                '\nLondon ($bLabel): $bLondon–$tLondon',
          ),

          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openMaps(t),
            icon: const Icon(Icons.map),
            label: const Text('Buka di Maps'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
