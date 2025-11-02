import 'package:flutter/material.dart';
import 'package:mangango/router.dart';
import 'package:mangango/services/session_service.dart';

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
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Image.asset(
                'assets/images/Logo.png',
                height: 200,
              ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
