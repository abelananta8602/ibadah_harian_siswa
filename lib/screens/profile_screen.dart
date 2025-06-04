import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
  List<String> badges = [];
  bool _subuhTodayChecked = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
    _refreshStatsAndBadges();
  }

  Future<void> _refreshStatsAndBadges() async {
    await hitungStatistik();
    periksaBadge();
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
    final String? allRiwayatJson = prefs.getString('riwayat_ibadah');

    List<Map<String, dynamic>> riwayatList = [];
    if (allRiwayatJson != null) {
      riwayatList = (json.decode(allRiwayatJson) as List)
          .cast<Map<String, dynamic>>();
    }

    int subuhTepat = 0;
    int hariPenuh = 0;
    bool subuhHariIni = false;

    final todayFormatted = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (var item in riwayatList) {
      final String? tanggal = item['tanggal'];
      if (tanggal == null) continue;

      final isSubuhChecked = item['Subuh'] as bool? ?? false;
      final isDzuhurChecked = item['Dzuhur'] as bool? ?? false;
      final isAsharChecked = item['Ashar'] as bool? ?? false;
      final isMaghribChecked = item['Maghrib'] as bool? ?? false;
      final isIsyaChecked = item['Isya'] as bool? ?? false;

      final isSubuhTepatWaktuSaved = item['isSubuhTepatWaktu'] as bool? ?? false;
      if (isSubuhChecked && isSubuhTepatWaktuSaved) {
        subuhTepat++;
      }
      if (tanggal == todayFormatted) {
        if (isSubuhChecked) {
          subuhHariIni = true;
        }
      }
      final semuaShalatDicentang = [
        isSubuhChecked,
        isDzuhurChecked,
        isAsharChecked,
        isMaghribChecked,
        isIsyaChecked,
      ];

      if (semuaShalatDicentang.every((s) => s == true)) {
        hariPenuh++;
      }
    }

    setState(() {
      jumlahSubuhTepatWaktu = subuhTepat;
      jumlahHariPenuh = hariPenuh;
      _subuhTodayChecked = subuhHariIni;
    });
  }

  Future<void> pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: const Color(0xFFF9F4FF),
      builder: (context) => SafeArea(
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

  void periksaBadge() {
    List<String> tempBadges = [];

    if (jumlahSubuhTepatWaktu >= 5) {
      tempBadges.add('🌅 Subuh Hero');
    }

    if (jumlahHariPenuh >= 5) {
      tempBadges.add('🔁 Konsisten Harian');
    }

    if (jumlahHariPenuh >= 10) {
      tempBadges.add('🕌 Ahli Ibadah');
    }

    setState(() {
      badges = tempBadges;
    });
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
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
                        _profileImage != null ? MemoryImage(_profileImage!) : null,
                    child: _profileImage == null
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
                    value: '$_subuhTodayChecked' == 'true' ? 'Selesai!' : '$jumlahSubuhTepatWaktu hari',
                    isSubuhCard: true,
                    subuhTodayChecked: _subuhTodayChecked,
                  ),
                  _StatCard(
                    icon: Icons.calendar_today,
                    label: 'Hari Penuh',
                    value: '$jumlahHariPenuh hari',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (badges.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Badge Prestasi:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: badges.map((badge) {
                    return Chip(
                      label: Text(
                        badge,
                        style: const TextStyle(fontSize: 14),
                      ),
                      backgroundColor: Colors.deepPurple[50],
                      avatar: const Icon(
                        Icons.emoji_events,
                        color: Colors.deepPurple,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  }).toList(),
                ),
              ],
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
                  await prefs.remove('riwayat_ibadah');
                  final oldKeysToDelete = prefs.getKeys().where((k) => k.startsWith('checklist_')).toList();
                  for (var key in oldKeysToDelete) {
                    await prefs.remove(key);
                  }

                  await prefs.remove('username');
                  await prefs.remove('profileImage');

                  setState(() {
                    jumlahSubuhTepatWaktu = 0;
                    jumlahHariPenuh = 0;
                    username = 'Nama Pengguna';
                    _profileImage = null;
                    _subuhTodayChecked = false;
                    badges = [];
                  });

                  await _refreshStatsAndBadges();
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
                child: const Text('Reset Data Ibadah & Profil'),
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
  final bool isSubuhCard;
  final bool subuhTodayChecked;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.isSubuhCard = false,
    this.subuhTodayChecked = false,
  });

  @override
  Widget build(BuildContext context) {
    IconData displayIcon = icon;
    String displayLabel = label;
    String displayValue = value;

    Color iconColor = Colors.deepPurple;
    Color cardColorStart = Colors.deepPurple[100]!;
    Color cardColorEnd = Colors.deepPurple[200]!;

    if (isSubuhCard) {
      if (subuhTodayChecked) {
        displayValue = 'Selesai!';
        displayLabel = 'Subuh Hari Ini';
        displayIcon = Icons.check_circle;
        iconColor = Colors.green;
        cardColorStart = Colors.green[100]!;
        cardColorEnd = Colors.green[200]!;
      } else {}}

    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColorStart, cardColorEnd],
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
            child: Icon(displayIcon, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayLabel,
            style: const TextStyle(fontSize: 14, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}