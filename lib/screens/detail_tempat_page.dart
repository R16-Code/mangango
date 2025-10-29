import 'package:flutter/material.dart';
import 'package:mangan_go/models/tempat.dart';
import 'package:mangan_go/services/currency_service.dart';
import 'package:mangan_go/services/time_service.dart';
import 'package:mangan_go/utils/maps_launcher.dart';

class DetailTempatPage extends StatefulWidget {
  // --- PERBAIKAN DI SINI ---
  final Tempat tempat;
  const DetailTempatPage({super.key, required this.tempat});
  // --- AKHIR PERBAIKAN ---

  @override
  State<DetailTempatPage> createState() => _DetailTempatPageState();
}

class _DetailTempatPageState extends State<DetailTempatPage> {
  Map<String, double> _currencyRates = {};
  bool _isLoading = true;
  String _currentTimeZone = 'WIB';
  
  // Service
  final CurrencyService _currencyService = CurrencyService();
  final TimeService _timeService = TimeService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final rates = await _currencyService.fetchAndCacheRates();
    if (mounted) {
      setState(() {
        _currencyRates = rates;
        _isLoading = false;
      });
    }
  }

  double _getMinPriceIDR() {
    try {
      final parts = widget.tempat.kisaranHarga.replaceAll('Rp', '').replaceAll('.', '').split('–');
      return double.parse(parts[0].trim());
    } catch (e) {
      return 0.0;
    }
  }

  Widget _buildCurrencyConversion(double priceIDR) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currencyRates.isEmpty) {
      return const Text('Gagal memuat kurs mata uang.', style: TextStyle(color: Colors.red));
    }

    final converted = _currencyService.convert(priceIDR, _currencyRates);
    
    String formatCurrency(String currency, double amount) {
      return '${currency == 'USD' ? '\$' : currency == 'JPY' ? '¥' : '€'} ${amount.toStringAsFixed(2)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Konversi Kisaran Harga Minimum (IDR):', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('USD (Amerika): ${formatCurrency('USD', converted['USD']!)}'),
        Text('JPY (Jepang): ${formatCurrency('JPY', converted['JPY']!)}'),
        Text('EUR (Eropa): ${formatCurrency('EUR', converted['EUR']!)}'),
      ],
    );
  }
  
  Widget _buildTimeConversion() {
    final List<String> timeZones = ['WIB', 'WITA', 'WIT', 'London'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Konversi Waktu Saat Ini:', style: TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: _currentTimeZone,
          items: timeZones.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _currentTimeZone = newValue!;
            });
          },
        ),
        const SizedBox(height: 8),
        Text('Waktu di $_currentTimeZone: ${_timeService.getCurrentTimeInZone(_currentTimeZone)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final minPriceIDR = _getMinPriceIDR();

    return Scaffold(
      appBar: AppBar(title: Text(widget.tempat.nama)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.tempat.nama,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 5),
                Text('${widget.tempat.rating.toStringAsFixed(1)} / 5.0'),
              ],
            ),
            const Divider(),
            _buildSection(
              title: 'Alamat',
              content: Text(widget.tempat.alamat),
              icon: Icons.location_on,
            ),
            _buildSection(
              title: 'Jam Operasional',
              content: Text('Buka: ${widget.tempat.jamBuka} - Tutup: ${widget.tempat.jamTutup}'),
              icon: Icons.schedule,
            ),
            _buildSection(
              title: 'Kisaran Harga',
              content: Text(widget.tempat.kisaranHarga),
              icon: Icons.price_change,
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10)
              ),
              child: _buildCurrencyConversion(minPriceIDR),
            ),
            
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10)
              ),
              child: _buildTimeConversion(),
            ),

            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                MapsLauncher.launchMaps(widget.tempat.latitude, widget.tempat.longitude);
              },
              icon: const Icon(Icons.navigation, color: Colors.white),
              label: const Text('Buka di Google Maps (Arah)', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget content, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.teal.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 28.0),
            child: content,
          ),
        ],
      ),
    );
  }
}