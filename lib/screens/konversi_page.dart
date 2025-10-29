import 'package:flutter/material.dart';

class KonversiPage extends StatefulWidget {
  const KonversiPage({super.key});

  @override
  State<KonversiPage> createState() => _KonversiPageState();
}

class _KonversiPageState extends State<KonversiPage> {
  // Halaman ini opsional, bisa digabung ke DetailTempatPage
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konversi Mata Uang & Waktu')),
      body: const Center(
        child: Text('Halaman Konversi (Akan diimplementasikan)'),
      ),
    );
  }
}
