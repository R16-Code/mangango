import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mangan_go/models/pengingat_makan.dart';
import 'package:mangan_go/services/notif_service.dart';
import 'package:mangan_go/services/session_service.dart';
import 'package:mangan_go/router.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  // Services
  final SessionService _sessionService = SessionService();
  final NotifService _notifService = NotifService();

  // Box Hive untuk pengingat
  late Box<PengingatMakan> _reminderBox;

  // State waktu (default WIB)
  TimeOfDay _pagi = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _siang = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _malam = const TimeOfDay(hour: 19, minute: 0);

  bool _loading = true;
  String _error = '';

  // Key penyimpanan di box
  static const String _reminderKey = 'default_reminder';

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    try {
      // Buka box 'reminders' (sudah dibuka di main.dart, tapi aman kalau dipanggil lagi)
      _reminderBox = Hive.box<PengingatMakan>('reminders');

      // Ambil data jika ada
      final PengingatMakan? current = _reminderBox.get(_reminderKey);
      if (current != null && current.times.isNotEmpty) {
        final times = current.times;
        // Harapkan format "HH:MM"
        if (times.isNotEmpty) _pagi = _parseHHmm(times[0]);
        if (times.length >= 2) _siang = _parseHHmm(times[1]);
        if (times.length >= 3) _malam = _parseHHmm(times[2]);
      } else {
        // Jika belum ada, simpan default
        await _saveTimes();
      }

      // Init notifikasi (sederhana)
      await _notifService.initialize();

      setState(() {
        _loading = false;
        _error = '';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Gagal memuat pengaturan: $e';
      });
    }
  }

  TimeOfDay _parseHHmm(String hhmm) {
    try {
      final parts = hhmm.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return const TimeOfDay(hour: 7, minute: 0);
    }
  }

  String _fmt(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _pickTime({
    required TimeOfDay current,
    required void Function(TimeOfDay) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked != null) {
      onPicked(picked);
      setState(() {}); // refresh tampilan tombol jam
    }
  }

  Future<void> _saveTimes() async {
    final times = <String>[_fmt(_pagi), _fmt(_siang), _fmt(_malam)];

    final PengingatMakan data = PengingatMakan(times: times);
    await _reminderBox.put(_reminderKey, data);

    // Tampilkan notifikasi sederhana sebagai feedback
    await _notifService.showSimple(
      'Pengingat Tersimpan',
      'Pagi ${times[0]}, Siang ${times[1]}, Malam ${times[2]}',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengingat makan berhasil disimpan.')),
      );
    }
  }

  Future<void> _logout() async {
    await _sessionService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.login,
      (route) => false,
    );
  }

  Widget _buildTimePicker({
    required String label,
    required IconData icon,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(label),
        trailing: Text(
          _fmt(time),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil & Notifikasi'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil & Notifikasi'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(
            _error,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Notifikasi'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pengingat Makan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          _buildTimePicker(
            label: 'Pagi',
            icon: Icons.wb_sunny_outlined,
            time: _pagi,
            onTap: () => _pickTime(
              current: _pagi,
              onPicked: (t) => _pagi = t,
            ),
          ),
          _buildTimePicker(
            label: 'Siang',
            icon: Icons.wb_sunny,
            time: _siang,
            onTap: () => _pickTime(
              current: _siang,
              onPicked: (t) => _siang = t,
            ),
          ),
          _buildTimePicker(
            label: 'Malam',
            icon: Icons.nightlight_round,
            time: _malam,
            onTap: () => _pickTime(
              current: _malam,
              onPicked: (t) => _malam = t,
            ),
          ),

          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _saveTimes,
            icon: const Icon(Icons.save),
            label: const Text('Simpan Pengingat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Akun',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
