import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int jumlahSubuhTepatWaktu = 0;
  int jumlahHariPenuh = 0;
  String username = 'Nama Pengguna';
  String? _profileImageUrl;
  List<String> badges = [];
  bool _subuhTodayChecked = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  User? _currentUser;
  @override
  void initState() {
    super.initState();

    _auth.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
        if (user != null) {
          _loadProfileAndStats();
        } else {

          setState(() {
            jumlahSubuhTepatWaktu = 0;
            jumlahHariPenuh = 0;
            username = 'Nama Pengguna';
            _profileImageUrl = null;
            badges = [];
            _subuhTodayChecked = false;
          });

        }
      }
    });
  }

  @override
  void dispose() {

    super.dispose();
  }

  Future<void> _loadProfileAndStats() async {
    if (_currentUser == null) return;
    await loadProfile();
    await hitungStatistik();
    periksaBadge();
  }

  Future<void> loadProfile() async {
    if (_currentUser == null) return;
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            username = userData['username'] ?? 'Nama Pengguna';
            _profileImageUrl = userData['profileImageUrl'];
          });
        }
      } else {
        if (mounted) {
          setState(() {
            username = 'Nama Pengguna';
            _profileImageUrl = null;
          });
        }
      }
    } catch (e) {
      print("Error loading profile from Firestore: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat profil: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> hitungStatistik() async {
    if (_currentUser == null) return;

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('checklists')
          .get();

      int subuhTepat = 0;
      int hariPenuh = 0;
      bool subuhHariIni = false;

      final todayFormatted = DateFormat('yyyy-MM-dd').format(DateTime.now());

      for (var doc in snapshot.docs) {
        Map<String, dynamic> item = doc.data() as Map<String, dynamic>;
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
      if (mounted) {
        setState(() {
          jumlahSubuhTepatWaktu = subuhTepat;
          jumlahHariPenuh = hariPenuh;
          _subuhTodayChecked = subuhHariIni;
        });
      }
    } catch (e) {
      print("Error counting statistics from Firestore: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghitung statistik: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> pickImage() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk mengubah foto profil.')),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Pilih Foto Profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: Theme.of(context).colorScheme.primary,
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
        try {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mengunggah foto profil...')),
            );
          }
          final bytes = await picked.readAsBytes();
          String filePath = 'images/profile/${_currentUser!.uid}.jpg';
          Reference ref = _storage.ref().child(filePath);

          UploadTask uploadTask = ref.putData(bytes);
          TaskSnapshot snapshot = await uploadTask;

          String downloadUrl = await snapshot.ref.getDownloadURL();

          await _firestore.collection('users').doc(_currentUser!.uid).set(
            {'profileImageUrl': downloadUrl},
            SetOptions(merge: true),
          );

          if (mounted) {
            setState(() {
              _profileImageUrl = downloadUrl;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Foto profil berhasil diunggah!')),
            );
          }
        } catch (e) {
          print("Error picking or uploading image: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengunggah foto profil: ${e.toString()}')),
            );
          }
        }
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

    if (mounted) {
      setState(() {
        badges = tempBadges;
      });
    }
  }

  Future<void> tampilkanDialogUbahNama(BuildContext context) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk mengubah nama.')),
      );
      return;
    }

    TextEditingController controller = TextEditingController(
      text: username,
    );

    await showGeneralDialog(
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
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
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
                      Icon(
                        Icons.person,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ubah Nama',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        decoration: InputDecoration(
                          hintText: 'Masukkan nama baru',
                          hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                          filled: true,
                          fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
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
                            child: Text(
                              'Batal',
                              style: TextStyle(color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () async {
                              String newUsername = controller.text.trim();
                              if (newUsername.isNotEmpty && _currentUser != null) {
                                try {
                                  await _firestore.collection('users').doc(_currentUser!.uid).set(
                                    {'username': newUsername},
                                    SetOptions(merge: true),
                                  );
                                  if (mounted) {
                                    setState(() {
                                      username = newUsername;
                                    });
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Nama pengguna berhasil diubah!')),
                                    );
                                  }
                                } catch (e) {
                                  print("Error updating username in Firestore: $e");
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Gagal mengubah nama: ${e.toString()}')),
                                    );
                                  }
                                }
                              } else {
                                if (mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Nama tidak boleh kosong.')),
                                  );
                                }
                              }
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


  Future<void> _resetAllData() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk mereset data.')),
      );
      return;
    }

    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Reset Data'),
          content: const Text('Apakah Anda yakin ingin mereset semua data ibadah dan profil Anda? Tindakan ini tidak dapat dibatalkan.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirm) return;

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mereset data...')),
        );
      }
      await _firestore.collection('users').doc(_currentUser!.uid).delete();
      QuerySnapshot checklistSnapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('checklists')
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in checklistSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();


      if (_profileImageUrl != null) {
        try {
          Reference ref = _storage.refFromURL(_profileImageUrl!);
          await ref.delete();
          print("Profile image deleted from Storage.");
        } on FirebaseException catch (e) {
          if (e.code == 'object-not-found') {
            print("Image not found in Storage, perhaps already deleted or never uploaded.");
          } else {
            print("Error deleting profile image from Storage: $e");
          }
        } catch (e) {
          print("General error deleting profile image: $e");
        }
      }
      if (mounted) {
        setState(() {
          jumlahSubuhTepatWaktu = 0;
          jumlahHariPenuh = 0;
          username = 'Nama Pengguna';
          _profileImageUrl = null;
          _subuhTodayChecked = false;
          badges = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua data ibadah dan profil berhasil direset!')),
        );
      }
    } catch (e) {
      print("Error resetting data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan saat mereset data: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 60, color: Colors.deepPurple),
              const SizedBox(height: 20),
              Text(
                'Silakan Login untuk melihat Profil Anda',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    backgroundImage:
                        _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                    child: _profileImageUrl == null
                        ? Icon(
                            Icons.person,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                username,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCard(
                    icon: Icons.alarm_on,
                    label: 'Subuh Tepat Waktu',
                    value: _subuhTodayChecked ? 'Selesai!' : '$jumlahSubuhTepatWaktu hari',
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Badge Prestasi:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
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
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      avatar: Icon(
                        Icons.emoji_events,
                        color: Theme.of(context).colorScheme.primary,
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
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  foregroundColor: Theme.of(context).colorScheme.primary,
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
                onPressed: _resetAllData,
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

    Color iconColor = Theme.of(context).colorScheme.primary;
    Color cardColorStart = Theme.of(context).colorScheme.primary.withOpacity(0.1);
    Color cardColorEnd = Theme.of(context).colorScheme.primary.withOpacity(0.2);

    if (isSubuhCard) {
      if (subuhTodayChecked) {
        displayValue = 'Selesai!';
        displayLabel = 'Subuh Hari Ini';
        displayIcon = Icons.check_circle;
        iconColor = Colors.green;
        cardColorStart = Colors.green[100]!;
        cardColorEnd = Colors.green[200]!;
      }
    }

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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.onPrimary,
            child: Icon(displayIcon, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayLabel,
            style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}