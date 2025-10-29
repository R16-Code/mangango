import 'package:flutter/material.dart';
import 'package:mangan_go/router.dart';
import 'package:mangan_go/services/session_service.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  final SessionService _session = SessionService();

  @override
  void initState() {
    super.initState();
    // Pastikan dieksekusi setelah frame pertama ter-build
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLogin());
  }

  Future<void> _checkLogin() async {
    try {
      // Efek splash singkat
      await Future.delayed(const Duration(seconds: 2));

      final userId = await _session.getLoggedInUserId(); // aman: auto-open box
      if (!mounted) return;

      final loggedIn = userId != null;
      if (loggedIn) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.home, (_) => false);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.login, (_) => false);
      }
    } catch (_) {
      // Hard fallback: kalau ada error apa pun, arahkan ke login
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.login, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 90, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Mangan Go',
              style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
