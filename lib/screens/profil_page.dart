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

  // Contoh state pengingat makan (placeholder sederhana).
  // Kalau kamu sudah punya field aslinya di Hive/SharedPreferences, tinggal mapping di _load().
  TimeOfDay? _pagi = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay? _siang = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay? _malam = const TimeOfDay(hour: 19, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = await _session.getLoggedInUserId();
    if (userId != null) {
      final box = Hive.box<Pengguna>('users');
      _user = box.get(userId);
    }
    setState(() => _loading = false);
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

  String _fmt(TimeOfDay? t) {
    if (t == null) return '-';
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _save() async {
    // Jika kamu punya box/settings khusus, simpan di sana.
    // Placeholder: cuma snackbar biar jelas posisi tombol Simpan.
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
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
        // Penting: tetap pasang bottom nav di state loading
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    final username = _user?.username ?? 'Pengguna';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== Header: Foto profil default + Username (poin 4) =====
          Row(
            children: [
              // Foto profil default (semua user sama)
              // Pakai Asset kalau tersedia; kalau tidak, fallback ke ikon.
              ClipOval(
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Image.asset(
                    'assets/images/profile_default.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.person, size: 48, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  username,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ===== Kartu Pengingat Makan =====
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pengingat Makan', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  _ReminderTile(
                    label: 'Pagi',
                    timeText: _fmt(_pagi),
                    onPick: () => _pickTime(
                      current: _pagi,
                      onSelected: (t) => _pagi = t,
                    ),
                  ),
                  _DividerThin(),
                  _ReminderTile(
                    label: 'Siang',
                    timeText: _fmt(_siang),
                    onPick: () => _pickTime(
                      current: _siang,
                      onSelected: (t) => _siang = t,
                    ),
                  ),
                  _DividerThin(),
                  _ReminderTile(
                    label: 'Malam',
                    timeText: _fmt(_malam),
                    onPick: () => _pickTime(
                      current: _malam,
                      onSelected: (t) => _malam = t,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tombol Simpan (poin 4)
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Simpan'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tombol Logout tepat di bawah Simpan (poin 4)
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _logout,
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ===== Bottom Navigation SELALU ada di Profil (poin 3) =====
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 1, // Profil = tab ke-2
      selectedItemColor: Colors.teal,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, AppRouter.home);
        } else if (index == 1) {
          // sudah di Profil
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
          label: 'Profil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.lightbulb),
          label: 'Saran & Kesan',
        ),
      ],
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final String label;
  final String timeText;
  final VoidCallback onPick;

  const _ReminderTile({
    required this.label,
    required this.timeText,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: TextButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.schedule),
        label: Text(timeText),
      ),
    );
  }
}

class _DividerThin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 8, thickness: 0.6, color: Colors.grey.shade300);
  }
}
