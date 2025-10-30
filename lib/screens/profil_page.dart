import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mangan_go/models/pengguna.dart';
import 'package:mangan_go/router.dart';
import 'package:mangan_go/services/session_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SessionService _session = SessionService();

  Pengguna? _user;
  bool _loading = true;

  // State pengingat makan (default)
  TimeOfDay? _pagi = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay? _siang = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay? _malam = const TimeOfDay(hour: 19, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---------- Helpers waktu ----------
  String _fmt(TimeOfDay? t) {
    if (t == null) return '-';
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  // parse "HH:mm" → TimeOfDay?
  TimeOfDay? _parseHHmm(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _pickTime({
    required TimeOfDay? current,
    required void Function(TimeOfDay) onSelected,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      onSelected(picked);
      setState(() {});
    }
  }

  // ---------- Load & Save ----------
  Future<void> _load() async {
    // ambil userId dari session (String?)
    final userId = await _session.getLoggedInUserId();

    if (userId != null) {
      final boxUsers = Hive.box<Pengguna>('users');
      _user = boxUsers.get(userId); // key String sesuai Pengguna.id
    }

    // Baca reminderTimes dari user (format ['HH:MM','HH:MM','HH:MM'])
    final times = _user?.reminderTimes ?? const ['07:00', '12:00', '19:00'];
    String? _safeGet(List<String> l, int i) => (i >= 0 && i < l.length) ? l[i] : null;

    _pagi  = _parseHHmm(_safeGet(times, 0)) ?? const TimeOfDay(hour: 7,  minute: 0);
    _siang = _parseHHmm(_safeGet(times, 1)) ?? const TimeOfDay(hour: 12, minute: 0);
    _malam = _parseHHmm(_safeGet(times, 2)) ?? const TimeOfDay(hour: 19, minute: 0);

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan: user tidak ditemukan.')),
      );
      return;
    }

    // Simpan format 'HH:mm' ke list di model Pengguna
    _user!.reminderTimes = [
      _fmt(_pagi),  // contoh: '07:00'
      _fmt(_siang), // '12:00'
      _fmt(_malam), // '19:00'
    ];

    await _user!.save(); // persist ke Hive

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengingat makan disimpan.')),
    );
  }

  Future<void> _logout() async {
    await _session.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2A2A2A),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Profil',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/main_bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    final username = _user?.username ?? 'Pengguna';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
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
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Avatar
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/profile_default.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: Colors.white,
                          child: const Icon(Icons.person, size: 60, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Username
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 32),

                // Card Pengingat Makan
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A).withOpacity(0.90),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pengingat Makan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _ReminderRow(
                        label: 'Pagi',
                        timeText: _fmt(_pagi),
                        onPick: () => _pickTime(
                          current: _pagi,
                          onSelected: (t) => _pagi = t,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _ReminderRow(
                        label: 'Siang',
                        timeText: _fmt(_siang),
                        onPick: () => _pickTime(
                          current: _siang,
                          onSelected: (t) => _siang = t,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _ReminderRow(
                        label: 'Malam',
                        timeText: _fmt(_malam),
                        onPick: () => _pickTime(
                          current: _malam,
                          onSelected: (t) => _malam = t,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tombol Simpan
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Simpan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 1,
      backgroundColor: const Color(0xFF2A2A2A),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white38,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, AppRouter.home);
        } else if (index == 1) {
          // sudah di Profile
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, AppRouter.feedback);
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
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final String label;
  final String timeText;
  final VoidCallback onPick;

  const _ReminderRow({
    required this.label,
    required this.timeText,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                timeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}