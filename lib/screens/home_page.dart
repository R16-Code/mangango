import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:mangango/models/pengguna.dart';
import 'package:mangango/models/tempat.dart';
import 'package:mangango/router.dart';
import 'package:mangango/services/lokasi_service.dart';
import 'package:mangango/services/session_service.dart';
import 'package:mangango/services/tempat_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LokasiService _lokasiService = LokasiService();
  final TempatService _tempatService = TempatService();
  final SessionService _session = SessionService();

  bool _loading = true;
  bool _showDeniedBanner = false;

  // fallback default 
  // (Tugu Jogja)
  Position? _userPosition;
  final double _fallbackLat = -7.782889;
  final double _fallbackLon = 110.367083;

  List<Tempat> _listTempat = [];

  final TextEditingController _searchController = TextEditingController();
  double _minRating = 0;
  double _maxDistanceKm = 100;

  // untuk  dropdown
  final List<double> _ratingOptions = const [0, 1, 2, 3, 4, 5];
  final List<double> _distanceOptions = const [1, 2, 3, 5, 10, 100];

  String _username = 'User';

  @override
  void initState() {
    super.initState();
    _checkSession(); 
    _loadUsername();   
    _initLoadPlaces();
  }

  Future<void> _checkSession() async {
    final userId = await _session.getLoggedInUserId();
    if (userId == null) {
      // sesi expired -> login
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.login);
      }
      return;
    }
  }

  Future<void> _loadUsername() async {
    final userId = await _session.getLoggedInUserId();
    if (userId != null) {
      final box = Hive.box<Pengguna>('users');
      final user = box.get(userId);
      if (mounted) {
        setState(() => _username = user?.username ?? 'User');
      }
    } else {
      if (mounted) {
        setState(() => _username = 'User');
      }
    }
  }

  Future<void> _initLoadPlaces() async {
    setState(() => _loading = true);
    
    final (pos, status) = await _lokasiService.getCurrentPosition();

    if (pos != null) {
      _userPosition = pos;
      _showDeniedBanner = false;
    } else {
      _userPosition = null;
      if (status == "denied" || status == "denied_forever") {
        _showDeniedBanner = true;
      }
    }

    _refreshList();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _refreshList() {
    final result = _tempatService.searchFilterSort(
      userPos: _userPosition,
      searchKeyword: _searchController.text.trim(),
      minRating: _minRating,
      maxDistanceKm: _maxDistanceKm,
      fallbackLat: _fallbackLat,
      fallbackLon: _fallbackLon,
    );

    setState(() => _listTempat = result);
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _minRating = 0;
      _maxDistanceKm = 100;
    });
    _refreshList();
  }

  Future<void> _retryGetRealLocation() async {
    final (newPos, status) = await _lokasiService.getCurrentPosition();

    if (newPos != null) {
      _userPosition = newPos;
      _showDeniedBanner = false;
      _refreshList();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi ditemukan — jarak diperbarui ✅')),
      );
      return;
    }

    if (!mounted) return;
    if (status == "denied_forever") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin lokasi diblokir permanen ⚠️')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat memperoleh lokasi 😕')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      body: Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/images/main_bg.png'),
        fit: BoxFit.cover,
      ),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 20,
              20,
              20,
            ),
              decoration: const BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, $_username',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Selamat Datang di Mangan Go',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Search
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _refreshList(),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      hintText: 'Cari tempat makan...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filter
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Rating minimal',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF1A1A1A),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<double>(
                              value: _minRating,
                              dropdownColor: const Color(0xFF2A2A2A),
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              items: _ratingOptions
                                  .map((r) => DropdownMenuItem(
                                        value: r,
                                        child: Text('⭐ ${r.toStringAsFixed(0)}'),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val == null) return;
                                setState(() => _minRating = val);
                                _refreshList();
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Jarak maksimal',
                            labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF1A1A1A),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<double>(
                              value: _maxDistanceKm,
                              dropdownColor: const Color(0xFF2A2A2A),
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              items: _distanceOptions
                                  .map((d) => DropdownMenuItem(
                                        value: d,
                                        child: Text('${d.toStringAsFixed(0)} km'),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val == null) return;
                                setState(() => _maxDistanceKm = val);
                                _refreshList();
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _resetFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_showDeniedBanner)
              Dismissible(
                key: const Key('denied_banner'),
                direction: DismissDirection.horizontal,
                onDismissed: (_) {
                  setState(() => _showDeniedBanner = false);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: Colors.orange.shade200,
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.black87),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Lokasi tidak diizinkan — menggunakan Tugu Jogja',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                      TextButton(
                        onPressed: _retryGetRealLocation,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),

            // List Tempat
            Expanded(
              child: _listTempat.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada tempat yang cocok 😕',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _listTempat.length,
                      itemBuilder: (context, index) {
                        final t = _listTempat[index];
                        final jarak = t.distanceKm?.toStringAsFixed(2) ?? '-';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRouter.detail,
                                arguments: t,
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.nama,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t.alamat,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$jarak km',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Color(0xFFFFEB3B), size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${t.rating}',
                                          style: const TextStyle(
                                            color: Color(0xFFFFEB3B),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
          if (index == 1) {
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
}