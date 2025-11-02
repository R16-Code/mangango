import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mangango/models/tempat.dart';
import 'package:mangango/router.dart';
import 'package:mangango/services/session_service.dart';
import 'package:mangango/utils/haversine.dart';
import 'package:mangango/utils/maps_launcher.dart';
import 'package:mangango/services/currency_service.dart';
import 'package:mangango/services/eta_service.dart'; // ⟵ TAMBAH
import 'package:mangango/services/lokasi_service.dart'; // ⟵ TAMBAH

class DetailTempatPage extends StatefulWidget {
  final Tempat tempat;
  const DetailTempatPage({super.key, required this.tempat});

  @override
  State<DetailTempatPage> createState() => _DetailTempatPageState();
}

class _DetailTempatPageState extends State<DetailTempatPage> {
  final CurrencyService _currency = CurrencyService();
  final LokasiService _lokasiService = LokasiService(); // ⟵ TAMBAH
  final EtaService _etaService = EtaService(); // ⟵ TAMBAH
  final SessionService _session = SessionService();
  
  Map<String, double>? _rates;
  bool _loadingRates = true;

  // ⟵ TAMBAH: State untuk ETA system
  EtaResult? _etaResult;
  bool _loadingEta = false;
  bool _showAccuracyBadge = false;
  bool _walkingMode = false;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _checkSession();
    _loadRates();
    _initEta(); // ⟵ TAMBAH: Initialize ETA system
  }

  Future<void> _checkSession() async {
  final userId = await _session.getLoggedInUserId();
  if (userId == null) {
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
    return;
  }
}

  // ⟵ TAMBAH: Method untuk ETA system
  Future<void> _initEta() async {
    // Dapatkan posisi user
    final (position, _) = await _lokasiService.getCurrentPosition();
    if (position != null) {
      setState(() => _userPosition = position);
    }

    // Load ETA driving-car secara otomatis
    _loadEta(mode: 'driving-car');
  }

  Future<void> _loadEta({required String mode}) async {
    // mode harus: 'driving-car' atau 'foot-walking' (sesuai ORS)
    final result = await _etaService.getEta(
      userLat: _userPosition!.latitude,
      userLon: _userPosition!.longitude,
      placeLat: widget.tempat.latitude,
      placeLon: widget.tempat.longitude,
      mode: mode, // 'driving-car' atau 'foot-walking'
    );

    if (!mounted) return;
    
    setState(() {
      _etaResult = result;
      _loadingEta = false;
      _walkingMode = (mode == 'foot-walking');
      
      // Tampilkan badge "Akurasi diperbarui" jika data fresh dari ORS
      if (!result.fromCache && !result.isFallback) {
        _showAccuracyBadge = true;
        // Auto-hide setelah 5 detik
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _showAccuracyBadge = false);
        });
      }
    });
  }

  // ⟵ TAMBAH: Widget untuk menampilkan ETA info
Widget _buildEtaInfo() {
  final t = widget.tempat;
  
  if (_userPosition == null) {
    final haversineKm = haversineDistanceKm(
      -7.782889, 110.367083,
      t.latitude,
      t.longitude,
    );
    return _buildEtaCard(
      '📍 Perkiraan Jarak',
      '${haversineKm.toStringAsFixed(1)} km',
      isEstimate: true,
    );
  }

  if (_loadingEta) {
    return _buildEtaCard(
      _walkingMode ? '🚶‍♂️ Menghitung Rute Jalan Kaki' : '🚗 Menghitung Rute Kendaraan',
      'Mohon tunggu...',
      isLoading: true,
    );
  }

  if (_etaResult != null) {
    final eta = _etaResult!;
    final modeText = _walkingMode ? '🚶‍♂️ Jalan Kaki' : '🚗 Kendaraan';
    final distanceText = '${eta.distanceKm.toStringAsFixed(1)} km';
    final timeText = '${eta.durationMin} menit';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEtaCard(
          modeText,
          '$timeText • $distanceText',
          isEstimate: eta.isFallback,
        ),
        if (_showAccuracyBadge)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green, width: 1),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 14),
                SizedBox(width: 6),
                Text(
                  'Akurasi diperbarui',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        _buildModeToggle(),
      ],
    );
  }

  final haversineKm = haversineDistanceKm(
    _userPosition!.latitude,
    _userPosition!.longitude,
    t.latitude,
    t.longitude,
  );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildEtaCard(
        '📍 Perkiraan Jarak',
        '${haversineKm.toStringAsFixed(1)} km',
        isEstimate: true,
      ),
      const SizedBox(height: 12),
      _buildModeToggle(),
    ],
  );
}

// ⟵ BUAT METHOD BARU untuk tampilan card yang rapi
Widget _buildEtaCard(String title, String value, {bool isEstimate = false, bool isLoading = false}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isEstimate ? Colors.orange.withOpacity(0.3) : Colors.white10,
        width: 1,
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              isLoading
                  ? Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      value,
                      style: TextStyle(
                        color: isEstimate ? Colors.orange : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ⟵ BUAT METHOD BARU untuk toggle button yang rapi
Widget _buildModeToggle() {
  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: Colors.white10, width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToggleButton(
          icon: Icons.directions_car,
          label: 'Kendaraan',
          isActive: !_walkingMode,
          onTap: () => _loadEta(mode: 'driving-car'),
        ),
        const SizedBox(width: 4),
        _buildToggleButton(
          icon: Icons.directions_walk,
          label: 'Jalan Kaki',
          isActive: _walkingMode,
          onTap: () => _loadEta(mode: 'foot-walking'),
        ),
      ],
    ),
  );
}

// ⟵ BUAT METHOD BARU untuk individual toggle button
Widget _buildToggleButton({
  required IconData icon,
  required String label,
  required bool isActive,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isActive ? Colors.white : Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}


  // 🎯 TANPA PERUBAHAN: Semua method existing tetap sama
  Future<void> _loadRates() async {
    final rates = await _currency.fetchAndCacheRates();
    if (!mounted) return;
    setState(() {
      _rates = rates;
      _loadingRates = false;
    });
  }

  DateTime _parseWibToday(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.elementAt(0)) ?? 0;
    final m = int.tryParse(parts.elementAt(1)) ?? 0;
    final nowLocal = DateTime.now();
    final baseUtc = DateTime.utc(nowLocal.year, nowLocal.month, nowLocal.day, 0, 0);
    return baseUtc.add(Duration(hours: h - 7, minutes: m));
  }

  String _fmtHHmm(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

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
      return lastOfMonth.subtract(Duration(days: lastOfMonth.weekday % 7));
    }

    final y = dayUtc.year;
    final start = lastSunday(y, 3).add(const Duration(hours: 1));
    final end   = lastSunday(y, 10).add(const Duration(hours: 1));
    return !dayUtc.isBefore(start) && !dayUtc.isAfter(end);
  }

  (String hhmm, String label) _fromWIBtoLondon(String hhmm) {
    final todayUtc = DateTime.now().toUtc();
    final isBST = _isLondonBST(todayUtc);
    final offset = isBST ? 1 : 0;
    final converted = _fromWIBtoOffset(hhmm, offset);
    return (converted, isBST ? 'BST' : 'GMT');
  }

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
    
    final (bLondon, bLabel) = _fromWIBtoLondon(t.jamBuka);
    final (tLondon, tLabel) = _fromWIBtoLondon(t.jamTutup);
    final bukaWITA = _fromWIBtoOffset(t.jamBuka, 8);
    final tutupWITA = _fromWIBtoOffset(t.jamTutup, 8);
    final bukaWIT = _fromWIBtoOffset(t.jamBuka, 9);
    final tutupWIT = _fromWIBtoOffset(t.jamTutup, 9);

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

                            // 🆕 TAMBAH: Info ETA & Jarak
                            _buildInfoSection(
                              icon: Icons.directions,
                              title: 'Perkiraan Jarak & Waktu',
                              children: [
                                _buildEtaInfo(), // ⟵ Widget ETA baru
                              ],
                            ),
                            const SizedBox(height: 20),

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

  // 🎯 TANPA PERUBAHAN: Helper methods existing
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