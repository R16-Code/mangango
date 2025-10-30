import 'package:flutter/material.dart';
import 'package:mangan_go/router.dart';

class SaranKesanPage extends StatelessWidget {
  const SaranKesanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Feedback',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/main_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSectionCard(
                  title: 'Kesan Pengembang',
                  content:
                      'Kami bangga telah menyelesaikan "Mangan Go" dengan pendekatan yang sederhana dan efisien. '
                      'Fokus pada pemisahan logika ke Service dan penggunaan Hive sebagai database lokal membuat proyek ini mudah dipahami oleh pemula Flutter. '
                      'Ini membuktikan bahwa fitur kompleks seperti LBS, hashing, dan konversi mata uang bisa diimplementasikan tanpa arsitektur berlebihan. '
                      'Kesederhanaan adalah kunci untuk presentasi yang jelas dan efektif!',
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Saran untuk Pengembangan Lanjut',
                  content:
                      'Untuk pengembangan ke depan, disarankan untuk:\n\n'
                      '1. Integrasi dengan API Maps sungguhan untuk tampilan peta yang lebih baik.\n'
                      '2. Menggunakan state management seperti Provider/Riverpod untuk skala aplikasi lebih besar.\n'
                      '3. Implementasi fitur Favorite dengan penyimpanan di Hive.',
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Catatan',
                  content:
                      'Aplikasi ini dibangun menggunakan Flutter dan hanya mengandalkan setState() untuk manajemen status.',
                  italic: true,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        backgroundColor: const Color(0xFF2A2A2A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, AppRouter.home);
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, AppRouter.profile);
          } else if (index == 2) {
            // sudah di Feedback
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Feedback',
          ),
        ],
      ),
    );
  }

  // ===== Helper private untuk membuat card section agar konsisten dan rapih =====
  Widget _buildSectionCard({
    required String title,
    required String content,
    bool italic = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A).withOpacity(0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // Isi
          Text(
            content,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.white,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}