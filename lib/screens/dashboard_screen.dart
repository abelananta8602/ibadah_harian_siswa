import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ibadah_harian_siswa/screens/doa_list_screen.dart';
import 'package:ibadah_harian_siswa/screens/doa_screen.dart';
import 'package:ibadah_harian_siswa/screens/hadith_list_screen.dart';
import 'package:ibadah_harian_siswa/screens/hadith_screen.dart';
import 'package:ibadah_harian_siswa/screens/qiblat_screen.dart';
import 'package:ibadah_harian_siswa/screens/quran_screen.dart';
import 'check_ibadah_screen.dart';
import 'riwayat_screen.dart';
import 'profile_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  String _username = 'Pengguna';

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
        if (user != null) {
          _loadUsername(user.uid);
        } else {
          setState(() {
            _username = 'Pengguna';
          });
        }
      }
    });
  }

  Future<void> _loadUsername(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (mounted) {
        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _username = userData['username'] ?? 'Pengguna';
          });
        }
      } else {
        setState(() {
          _username = 'Pengguna';
        });
      }
    } catch (e) {
      print("Error loading username: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 120, 
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 16.0, 8.0), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Assalamu\'alaikum $_username 👋',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ayo semangat ibadah hari ini!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.0,
          ),
          itemCount: _dashboardItems.length,
          itemBuilder: (context, index) {
            final item = _dashboardItems[index];
            return _DashboardCard(
              icon: item['icon'] as IconData,
              title: item['title'] as String,
              onTap: item['onTap'] as VoidCallback,
            );
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _dashboardItems {
    return [
      {
        'icon': Icons.check_circle_outline,
        'title': 'Cek Ibadah Hari Ini',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CheckIbadahScreen()),
          );
        },
      },
      {
        'icon': Icons.history,
        'title': 'Lihat Riwayat',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RiwayatScreen()),
          );
        },
      },
      {
        'icon': Icons.menu_book,
        'title': 'Baca Al-Quran',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QuranScreen()),
          );
        },
      },
      {
        'icon': Icons.auto_stories,
        'title': 'Baca Hadits',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HadithListScreen()),
          );
        },
      },
      {
        'icon': Icons.self_improvement,
        'title': 'Doa Harian',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DoaListScreen()),
          );
        },
      },
      {
        'icon': Icons.explore,
        'title': 'Kiblat',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QiblatScreen()),
          );
        },
      },
    ];
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}