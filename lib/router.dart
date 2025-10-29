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
