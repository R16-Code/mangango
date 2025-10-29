import 'package:flutter/material.dart';

class PengingatPage extends StatefulWidget {
  const PengingatPage({super.key});

  @override
  State<PengingatPage> createState() => _PengingatPageState();
}

class _PengingatPageState extends State<PengingatPage> {
  // Halaman ini mungkin tidak dipakai jika digabung ke ProfilPage
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atur Pengingat Makan')),
      body: const Center(
        child: Text('Halaman Pengingat (Akan diimplementasikan)'),
      ),
    );
  }
}
