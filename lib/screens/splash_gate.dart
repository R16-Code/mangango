import 'package:flutter/material.dart';
import 'package:mangan_go/router.dart';
import 'package:mangan_go/services/session_service.dart';
import 'package:mangan_go/services/tempat_service.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  final SessionService _sessionService = SessionService();
  final TempatService _tempatService = TempatService();

  @override
  void initState() {
    super.initState();
    // Panggil fungsi inisialisasi setelah widget selesai di-build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    // 1. Lakukan Seeding Data (Jika Belum Ada)
    // Logika ini memastikan data tempat makan ada di Hive
    try {
      await _tempatService.seedPlacesFromJson(context);
    } catch (e) {
      // Tampilkan error jika gagal membaca JSON atau inisialisasi
      print('Error seeding data: $e');
      // Anda bisa menampilkan dialog error di sini, tapi untuk kesederhanaan kita log saja.
    }

    // Tunggu sebentar untuk efek splash
    await Future.delayed(const Duration(seconds: 1));

    // 2. Cek Status Login
    final bool loggedIn = await _sessionService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      // Jika sudah login, langsung ke Home Page
      Navigator.of(context).pushReplacementNamed(AppRouter.home);
    } else {
      // Jika belum login, ke Login Page
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 
            Text(
              'Mangan Go!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 10),
            Text('Memuat data dan memeriksa sesi...'),
          ],
        ),
      ),
    );
  }
}

// Catatan: Untuk TempatService(), kita akan buat file ini di langkah selanjutnya.
// Pastikan Anda juga membuat semua screens placeholder lainnya di lib/screens:
// login_page.dart, register_page.dart, home_page.dart, detail_tempat_page.dart,
// profil_page.dart, saran_kesan_page.dart, konversi_page.dart
