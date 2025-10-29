import 'package:flutter/material.dart';
import 'package:mangan_go/router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mangan Go - Jogja Food Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Tema sederhana, bisa disesuaikan nanti
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter', // Contoh font
      ),
      // Mendaftarkan semua rute yang sudah didefinisikan di AppRouter
      initialRoute: AppRouter.splashGate,
      routes: AppRouter.routes,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
