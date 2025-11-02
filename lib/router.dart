// mengatur navigasi
import 'package:flutter/material.dart';
import 'package:mangango/models/tempat.dart';
import 'package:mangango/screens/detail_tempat_page.dart';
import 'package:mangango/screens/home_page.dart';  // ⬅️ IMPORT INI
import 'package:mangango/screens/login_page.dart';
import 'package:mangango/screens/profil_page.dart';
import 'package:mangango/screens/register_page.dart';
import 'package:mangango/screens/saran_kesan_page.dart';
import 'package:mangango/screens/splash_gate.dart';

class AppRouter {
  static const String splashGate = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String detail = '/detail';
  static const String profile = '/profile';
  static const String feedback = '/feedback';

  static final Map<String, WidgetBuilder> routes = {
    splashGate: (_) => const SplashGate(),
    login: (_) => const LoginPage(),
    register: (_) => const RegisterPage(),
    home: (_) => const HomePage(), 
    profile: (_) => const ProfilePage(),
    feedback: (_) => const SaranKesanPage(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == detail) {
      final arg = settings.arguments;
      if (arg is Tempat) {
        return MaterialPageRoute(builder: (_) => DetailTempatPage(tempat: arg));
      }
      return MaterialPageRoute(builder: (_) => const SplashGate());
    }
    return null;
  }
}