import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mangan_go/models/tempat.dart';
import 'package:mangan_go/router.dart';
import 'package:mangan_go/screens/profil_page.dart';
import 'package:mangan_go/screens/saran_kesan_page.dart';
import 'package:mangan_go/services/lokasi_service.dart';
import 'package:mangan_go/services/tempat_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String _errorMessage = '';
  Position? _userPosition;

  List<Tempat> _listTempat = [];
  List<Tempat> _originalListTempat = [];

  final TextEditingController _searchController = TextEditingController();
  double? _selectedMaxJarak;
  double? _selectedMinRating;

  final TempatService _tempatService = TempatService();
  final LokasiService _lokasiService = LokasiService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      _userPosition = await _lokasiService.getCurrentLocation();

      // Panggil service untuk mengambil data
      // Service akan menghitung jarak dan menyimpannya di 'jarakKm'
      final tempat = await _tempatService.getSortedPlaces(_userPosition!);
      
      setState(() {
        _originalListTempat = tempat;
        _listTempat = List.from(_originalListTempat); // Gunakan List.from
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    String query = _searchController.text.toLowerCase();
    
    // Mulai dari data asli
    List<Tempat> filteredList = List.from(_originalListTempat);

    // Filter Search (Nama)
    if (query.isNotEmpty) {
      filteredList = filteredList.where((tempat) {
        return tempat.nama.toLowerCase().contains(query);
      }).toList();
    }

    // Filter Jarak (Max Jarak) - Gunakan jarakKm yang sudah dihitung
    if (_selectedMaxJarak != null) {
      filteredList = filteredList.where((tempat) {
        // tempat.jarakKm diisi saat _loadData
        return tempat.jarakKm != null && tempat.jarakKm! <= _selectedMaxJarak!;
      }).toList();
    }

    // Filter Rating (Min Rating)
    if (_selectedMinRating != null) {
      filteredList = filteredList.where((tempat) {
        return tempat.rating >= _selectedMinRating!;
      }).toList();
    }

    setState(() {
      _listTempat = filteredList;
    });
  }

  Widget _buildHomePageContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('Error: $_errorMessage\n\nPastikan GPS aktif dan izin lokasi diberikan.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    return Column(
      children: [
        _buildSearchFilter(),
        Expanded(child: _buildPlaceList()),
      ],
    );
  }

  Widget _buildSearchFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.teal.shade50,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama tempat makan...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => _applyFilter(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFilterDropdown(
                hint: 'Jarak',
                value: _selectedMaxJarak,
                items: {
                  '≤ 1 km': 1.0,
                  '≤ 3 km': 3.0,
                  '≤ 5 km': 5.0,
                },
                onChanged: (val) {
                  setState(() { _selectedMaxJarak = val; });
                  _applyFilter();
                },
              ),
              _buildFilterDropdown(
                hint: 'Rating',
                value: _selectedMinRating,
                items: {
                  'Min 3.0 ★': 3.0,
                  'Min 4.0 ★': 4.0,
                  'Min 4.5 ★': 4.5,
                },
                onChanged: (val) {
                  setState(() { _selectedMinRating = val; });
                  _applyFilter();
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedMaxJarak = null;
                    _selectedMinRating = null;
                    _listTempat = List.from(_originalListTempat); // Reset
                  });
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String hint,
    required T? value,
    required Map<String, T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        hint: Text(hint),
        value: value,
        items: [
          DropdownMenuItem<T>(
            value: null,
            child: Text(hint, style: TextStyle(color: Colors.grey[600])),
          ),
          ...items.entries.map((entry) {
            return DropdownMenuItem<T>(
              value: entry.value,
              child: Text(entry.key),
            );
          }).toList(),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildPlaceList() {
    if (_listTempat.isEmpty) {
      return const Center(child: Text('Tidak ada tempat makan yang sesuai filter.'));
    }

    return ListView.builder(
      itemCount: _listTempat.length,
      itemBuilder: (context, index) {
        final tempat = _listTempat[index];
        
        // --- PERBAIKAN DI SINI ---
        // Ambil jarakKm yang sudah dihitung, jangan hitung ulang
        final jarak = tempat.jarakKm ?? 0.0;
        // --- AKHIR PERBAIKAN ---

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(tempat.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tempat.alamat, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(' ${tempat.rating.toStringAsFixed(1)}'),
                    const SizedBox(width: 10),
                    Icon(Icons.schedule, color: Colors.grey[600], size: 16),
                    Text(' ${tempat.jamBuka} - ${tempat.jamTutup}'),
                  ],
                ),
              ],
            ),
            trailing: Text(
              '${jarak.toStringAsFixed(1)} km',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 14),
            ),
            onTap: () {
              // --- PERBAIKAN DI SINI ---
              // Navigasi ke Detail, kirim objek 'tempat' sebagai argumen
              Navigator.pushNamed(context, AppRouter.detail, arguments: tempat);
              // --- AKHIR PERBAIKAN ---
            },
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePageContent();
      case 1:
        return const ProfilPage();
      case 2:
        return const SaranKesanPage();
      default:
        return _buildHomePageContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mangan Go (Jogja)'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _getSelectedPage(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil & Notifikasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: 'Saran & Kesan',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
      ),
    );
  }
}