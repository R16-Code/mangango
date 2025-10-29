import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mangan_go/models/tempat.dart';
import 'package:mangan_go/router.dart';
import 'package:mangan_go/services/lokasi_service.dart';
import 'package:mangan_go/services/tempat_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LokasiService _lokasiService = LokasiService();
  final TempatService _tempatService = TempatService();

  bool _loading = true;

  // flag agar banner dapat di-dismiss
  bool _showDeniedBanner = false;

  // posisi user & fallback default (Tugu Jogja)
  Position? _userPosition;
  final double _fallbackLat = -7.782889;
  final double _fallbackLon = 110.367083;

  List<Tempat> _listTempat = [];

  final TextEditingController _searchController = TextEditingController();
  double _minRating = 0;
  double _maxDistanceKm = 30;

  @override
  void initState() {
    super.initState();
    _initLoadPlaces();
  }

  Future<void> _initLoadPlaces() async {
    final (pos, status) = await _lokasiService.getCurrentPosition();

    if (pos != null) {
      _userPosition = pos;
      _showDeniedBanner = false;
    } else {
      // pakai fallback (Tugu Jogja)
      _userPosition = null; // kita kirim null ke service, lalu service pakai fallback lat/lon
      if (status == "denied" || status == "denied_forever") {
        _showDeniedBanner = true; // tampil banner
      }
    }

    _refreshList();
    setState(() => _loading = false);
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
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mangan Go (Jogja)'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mangan Go (Jogja)'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Banner B2 (dismissible)
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

          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _refreshList(),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade200,
                hintText: 'Cari tempat makan...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filter sliders
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Rating Min'),
                      Slider(
                        value: _minRating,
                        min: 0,
                        max: 5,
                        divisions: 5,
                        label: _minRating.toStringAsFixed(1),
                        onChanged: (v) {
                          setState(() => _minRating = v);
                          _refreshList();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Jarak Maks (km)'),
                      Slider(
                        value: _maxDistanceKm,
                        min: 1,
                        max: 30,
                        divisions: 29,
                        label: '${_maxDistanceKm.toStringAsFixed(0)} km',
                        onChanged: (v) {
                          setState(() => _maxDistanceKm = v);
                          _refreshList();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _listTempat.isEmpty
                ? const Center(child: Text('Tidak ada tempat yang cocok 😕'))
                : ListView.builder(
                    itemCount: _listTempat.length,
                    itemBuilder: (context, index) {
                      final t = _listTempat[index];
                      final jarak = t.distanceKm?.toStringAsFixed(2) ?? '-';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(
                            t.nama,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.alamat, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 16, color: Colors.amber),
                                  Text('${t.rating}   •   $jarak km'),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRouter.detail,
                              arguments: t,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.teal,
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
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: 'Saran & Kesan',
          ),
        ],
      ),
    );
  }
}
