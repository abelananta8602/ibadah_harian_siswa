import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int jumlahSubuhTepatWaktu = 0;
  int jumlahHariPenuh = 0;
  String username = 'Nama Pengguna';
  Uint8List? _profileImage;

  @override
  void initState() {
    super.initState();
    loadProfile();
    hitungStatistik();
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Nama Pengguna';
      String? imageData = prefs.getString('profileImage');
      if (imageData != null) {
        _profileImage = base64Decode(imageData);
      }
    });
  }

  Future<void> hitungStatistik() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    int subuhTepat = 0;
    Set<String> tanggalSet = {};
    Map<String, List<String>> dataHarian = {};

    for (String key in keys) {
      final value = prefs.getString(key);
      if (value == null) continue;

      if (key.startsWith('subuh_')) {
        final waktu = DateTime.tryParse(value);
        if (waktu != null && waktu.hour >= 4 && waktu.hour < 5) {
          subuhTepat++;
        }
      }

      final parts = key.split('_');
      if (parts.length == 2) {
        final waktuIbadah = parts[0];
        final tanggal = parts[1];

        dataHarian[tanggal] = dataHarian[tanggal] ?? [];
        dataHarian[tanggal]!.add(waktuIbadah);
        tanggalSet.add(tanggal);
      }
    }

    int hariPenuh =
        dataHarian.values
            .where(
              (list) => list.toSet().containsAll([
                'subuh',
                'dzuhur',
                'ashar',
                'maghrib',
                'isya',
              ]),
            )
            .length;

    setState(() {
      jumlahSubuhTepatWaktu = subuhTepat;
      jumlahHariPenuh = hariPenuh;
    });
  }

  Future<void> pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: const Color(0xFFF9F4FF),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Pilih Foto Profil',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Colors.deepPurple,
                  ),
                  title: const Text('Kamera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Colors.deepPurple,
                  ),
                  title: const Text('Galeri'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
    );

    if (source != null) {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImage', base64Encode(bytes));
        setState(() {
          _profileImage = bytes;
        });
      }
    }
  }

  Future<void> tampilkanDialogUbahNama(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String namaSekarang = prefs.getString('username') ?? '';
    TextEditingController controller = TextEditingController(
      text: namaSekarang,
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: Dialog(
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ubah Nama',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Masukkan nama baru',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.deepPurple,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Batal',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () async {
                              await prefs.setString(
                                'username',
                                controller.text.trim(),
                              );
                              await loadProfile();
                              Navigator.of(context).pop();
                            },
                            child: const Text('Simpan'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF9F4FF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFFE0D7F8),
                    backgroundImage:
                        _profileImage != null
                            ? MemoryImage(_profileImage!)
                            : null,
                    child:
                        _profileImage == null
                            ? const Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.deepPurple,
                            )
                            : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: pickImage,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.deepPurple,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                username,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCard(
                    icon: Icons.alarm_on,
                    label: 'Subuh Tepat Waktu',
                    value: '$jumlahSubuhTepatWaktu hari',
                  ),
                  _StatCard(
                    icon: Icons.calendar_today,
                    label: 'Hari Penuh',
                    value: '$jumlahHariPenuh hari',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => tampilkanDialogUbahNama(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple[100],
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Ubah Nama'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  setState(() {
                    jumlahSubuhTepatWaktu = 0;
                    jumlahHariPenuh = 0;
                    username = 'Nama Pengguna';
                    _profileImage = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Reset Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple[100]!, Colors.deepPurple[200]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(icon, color: Colors.deepPurple),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
