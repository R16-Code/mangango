import 'package:flutter/material.dart';
import 'package:mangan_go/router.dart';

class SaranKesanPage extends StatelessWidget {
  const SaranKesanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Saran & Kesan = tab ke-3
        selectedItemColor: Colors.teal,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, AppRouter.home);
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, AppRouter.profile);
          } else if (index == 2) {
            // sudah di Saran & Kesan, abaikan
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: 'Saran & Kesan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tab Saran & Kesan (Display Only)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const Divider(),
            const SizedBox(height: 10),
            
            _buildSection(
              title: 'Kesan Pengembang',
              content: 
                'Kami bangga telah menyelesaikan "Mangan Go" dengan pendekatan yang sederhana dan efisien. Fokus pada pemisahan logika ke Service dan penggunaan Hive sebagai database lokal membuat proyek ini sangat mudah dipahami oleh pemula Flutter. Ini membuktikan bahwa fitur kompleks seperti LBS, Hashing, dan Konversi Mata Uang bisa diimplementasikan tanpa arsitektur yang berlebihan. Kesederhanaan adalah kunci untuk presentasi yang jelas dan efektif!',
            ),

            const SizedBox(height: 20),

            _buildSection(
              title: 'Saran untuk Pengembangan Lanjut',
              content: 
                'Untuk pengembangan ke depan, disarankan untuk: \n'
                '1. Integrasi dengan API Maps sungguhan untuk tampilan peta yang lebih baik. \n'
                '2. Menggunakan State Management seperti Provider atau Riverpod untuk skala aplikasi yang lebih besar. \n'
                '3. Implementasi fitur "Favorite" dengan penyimpanan di Hive.',
            ),

            const SizedBox(height: 20),
            Text(
              'Aplikasi ini dibangun menggunakan Flutter dan hanya mengandalkan setState() untuk manajemen status.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        const SizedBox(height: 5),
        Text(
          content,
          textAlign: TextAlign.justify,
          style: TextStyle(fontSize: 16, height: 1.5, color: Colors.grey[800]),
        ),
      ],
    );
  }
}
