import 'package:flutter/material.dart';
import 'package:mangango/router.dart';

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
                  title: 'Kesan dan Saran untuk Mata Kuliah Pemrograman Mobile',
                  content:
                      '',

                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Kesan',
                  content:
                      'Secara keseluruhan, mata kuliah ini sangat menarik dan menantang jiwa raga. Karena Flutter adalah hal yang benar-benar baru bagi saya, rasanya cukup memuaskan bisa belajar dari nol hingga akhirnya memahami dasar-dasar pembuatan aplikasi mobile.\n\n',
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Saran',
                  content:
                      'Mungkin untuk tahun berikutnya bisa dipertimbangkan lagi dalam memberikan tenggat waktu yang lebih longgar untuk proyek akhirnya. Atau mungkin bisa langsung memberikan pengumpulan proyek akhir di spada sejak awal perkuliahan dimulai',
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Terima kasih atas pengalamannya yang sangat menyenangkan!😀',
                  content:
                      '',
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