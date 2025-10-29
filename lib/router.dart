import 'package:flutter/material.dart';
import 'package:mangan_go/models/tempat.dart';
import 'package:mangan_go/screens/detail_tempat_page.dart';
import 'package:mangan_go/screens/home_page.dart';
import 'package:mangan_go/screens/login_page.dart';
import 'package:mangan_go/screens/profil_page.dart';
import 'package:mangan_go/screens/register_page.dart';
import 'package:mangan_go/screens/saran_kesan_page.dart';
import 'package:mangan_go/screens/splash_gate.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String detail = '/detail';
  static const String profile = '/profile';
  static const String feedback = '/feedback';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashGate());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      
      // --- PERBAIKAN DI SINI ---
      // Logika untuk mengambil argumen 'tempat' saat navigasi
      case detail:
        final args = settings.arguments;
        // Cek apakah argumennya adalah objek Tempat
        if (args is Tempat) {
          return MaterialPageRoute(
            builder: (_) => DetailTempatPage(tempat: args),
          );
        }
        // Jika argumen salah, kembali ke Home (atau tampilkan error)
        return MaterialPageRoute(builder: (_) => const HomePage());
      // --- AKHIR PERBAIKAN ---

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilPage());
      case feedback:
        return MaterialPageRoute(builder: (_) => const SaranKesanPage());

      default:
        // Rute default jika tidak ditemukan
        return MaterialPageRoute(builder: (_) => const SplashGate());
    }
  }

  // Hapus 'routes' map jika menggunakan onGenerateRoute secara penuh
  // Ini adalah sumber error 'The named parameter 'tempat' is required'
}