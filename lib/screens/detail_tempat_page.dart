import 'package:flutter/material.dart';
import 'package:mangan_go/models/tempat.dart';
import 'package:mangan_go/router.dart';
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

void _openMaps(Tempat t) {
  MapsLauncher.openSmart(
    t.urlMaps.trim(),
    lat: t.latitude,
    lng: t.longitude,
    label: t.nama,
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

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        
        backgroundColor: const Color(0xFF2A2A2A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Tempat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/main_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    t.nama,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Color(0xFFFFEB3B), size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${t.rating}',
                                      style: const TextStyle(
                                        color: Color(0xFFFFEB3B),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              t.alamat,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ===== Kisaran Harga =====
                            _buildInfoSection(
                              icon: Icons.payments_outlined,
                              title: 'Kisaran Harga',
                              children: [
                                _buildInfoRow('Rp', idrText),
                                if (_loadingRates)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Memuat kurs...',
                                      style: TextStyle(color: Colors.white54, fontSize: 13),
                                    ),
                                  )
                                else if (_rates != null) ...[
                                  _buildInfoRow('USD', _toForeignRange(minIdr, maxIdr, _rates!, 'USD', symbol: '\$', fraction: 2)),
                                  _buildInfoRow('EUR', _toForeignRange(minIdr, maxIdr, _rates!, 'EUR', symbol: '€', fraction: 2)),
                                  _buildInfoRow('JPY', _toForeignRange(minIdr, maxIdr, _rates!, 'JPY', symbol: '¥', fraction: 0)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ===== Jam Operasional =====
                            _buildInfoSection(
                              icon: Icons.access_time_outlined,
                              title: 'Jam Operasional',
                              children: [
                                _buildInfoRow('WIB', '${t.jamBuka} - ${t.jamTutup}'),
                                _buildInfoRow('WITA', '$bukaWITA - $tutupWITA'),
                                _buildInfoRow('WIT', '$bukaWIT - $tutupWIT'),
                                _buildInfoRow('London', '$bLondon - $tLondon ($bLabel)'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ===== Tombol Buka di Maps =====
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _openMaps(t),
                      icon: const Icon(Icons.location_on, size: 24),
                      label: const Text(
                        'Buka di Maps',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: const Color(0xFF2A2A2A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, AppRouter.home);
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, AppRouter.profile);
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, AppRouter.feedback);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Feedback',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}