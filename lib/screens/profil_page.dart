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
  // Service
  final NotifService _notifService = NotifService();
  final SessionService _sessionService = SessionService();

  // State untuk Waktu
  TimeOfDay _pagiTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _siangTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _malamTime = const TimeOfDay(hour: 19, minute: 0);
  bool _isLoading = true;

  // Box Hive
  static const String _boxName = 'pengingatMakan';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<PengingatMakan>(_boxName);
    }
    final box = Hive.box<PengingatMakan>(_boxName);
    final settings = box.get('default');

    if (settings != null) {
      setState(() {
        // --- PERBAIKAN DI SINI ---
        _pagiTime = settings.pagi;
        _siangTime = settings.siang;
        _malamTime = settings.malam;
        // --- AKHIR PERBAIKAN ---
      });
    }
    setState(() { _isLoading = false; });
  }

  Future<void> _saveAndSchedule() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<PengingatMakan>(_boxName);
    }
    final box = Hive.box<PengingatMakan>(_boxName);
    
    // --- PERBAIKAN DI SINI ---
    final settings = PengingatMakan(
      pagi: _pagiTime,
      siang: _siangTime,
      malam: _malamTime,
    );
    // --- AKHIR PERBAIKAN ---
    
    await box.put('default', settings);

    await _notifService.cancelAllNotifications();
    
    await _notifService.scheduleDailyNotification(
      id: 0,
      title: 'Waktunya Sarapan! ☀️',
      body: 'Jangan lupa sarapan, Mangan Go mengingatkanmu!',
      time: _pagiTime,
    );
    await _notifService.scheduleDailyNotification(
      id: 1,
      title: 'Waktunya Makan Siang! 🍛',
      body: 'Sudah jam 12, yuk makan siang!',
      time: _siangTime,
    );
    await _notifService.scheduleDailyNotification(
      id: 2,
      title: 'Waktunya Makan Malam! 🌙',
      body: 'Selamat makan malam, jangan sampai telat!',
      time: _malamTime,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengingat berhasil disimpan dan dijadwalkan!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _selectTime(BuildContext context, TimeOfDay initialTime, ValueChanged<TimeOfDay> onTimeChanged) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null && picked != initialTime) {
      setState(() {
        onTimeChanged(picked);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profil & Pengingat Makan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const Divider(),
            
            const Text(
              'Atur Waktu Pengingat (Notifikasi Lokal)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _buildTimePicker(
              label: 'Sarapan (Pagi)',
              icon: Icons.wb_sunny_outlined,
              time: _pagiTime,
              onTap: () => _selectTime(context, _pagiTime, (time) => _pagiTime = time),
            ),
            _buildTimePicker(
              label: 'Makan Siang',
              icon: Icons.fastfood_outlined,
              time: _siangTime,
              onTap: () => _selectTime(context, _siangTime, (time) => _siangTime = time),
            ),
            _buildTimePicker(
              label: 'Makan Malam',
              icon: Icons.nights_stay_outlined,
              time: _malamTime,
              onTap: () => _selectTime(context, _malamTime, (time) => _malamTime = time),
            ),
            
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveAndSchedule,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Simpan & Jadwalkan Notifikasi', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            
            const SizedBox(height: 40),
            const Divider(),
            
            ElevatedButton.icon(
              onPressed: () async {
                await _sessionService.logout(); // Panggil service logout
                if(mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (route) => false);
                }
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker({required String label, required IconData icon, required TimeOfDay time, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(label),
        trailing: Text(
          time.format(context),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onTap: onTap,
      ),
    );
  }
}