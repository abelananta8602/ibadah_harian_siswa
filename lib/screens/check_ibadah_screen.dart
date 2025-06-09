import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';

class CheckIbadahScreen extends StatefulWidget {
  const CheckIbadahScreen({super.key});

  @override
  State<CheckIbadahScreen> createState() => _CheckIbadahScreenState();
}

class _CheckIbadahScreenState extends State<CheckIbadahScreen> {

  Map<String, bool> checklist = {
    'Subuh': false,
    'Dzuhur': false,
    'Ashar': false,
    'Maghrib': false,
    'Isya': false,
  };
  bool _isSubuhTepatWaktuCurrent = false;

  final Map<String, List<String>> waktuIbadah = {
    'Subuh': ['04:30', '06:00'],
    'Dzuhur': ['12:00', '15:00'],
    'Ashar': ['15:00', '17:30'],
    'Maghrib': ['18:00', '18:30'],
    'Isya': ['19:00', '04:00'],
  };

  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }
    _loadChecklistForToday();
  }


  void _updateUI() {
    _loadChecklistForToday();
  }


  Future<void> _loadChecklistForToday() async {
    if (_currentUser == null) return;

    final todayFormatted = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('checklists')
          .doc(todayFormatted)
          .get();

      setState(() {
        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          checklist.forEach((key, value) {
            checklist[key] = data[key] ?? false;
          });
          _isSubuhTepatWaktuCurrent = data['isSubuhTepatWaktu'] ?? false;
        } else {

          checklist.updateAll((key, value) => false);
          _isSubuhTepatWaktuCurrent = false;
        }
      });
    } catch (e) {
      print('Error loading checklist: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data checklist: $e')),
        );
      }
    }
  }


  Future<void> _simpanDataHarian(String namaSholat, bool isTepatWaktu) async {
    if (_currentUser == null) return;

    final todayFormatted = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('checklists')
        .doc(todayFormatted);

    try {

      DocumentSnapshot currentDoc = await docRef.get();
      Map<String, dynamic> dataHariIni = {};

      if (currentDoc.exists && currentDoc.data() != null) {
        dataHariIni = currentDoc.data() as Map<String, dynamic>;
      } else {

        dataHariIni = {
          'tanggal': todayFormatted,
          'Subuh': false,
          'Dzuhur': false,
          'Ashar': false,
          'Maghrib': false,
          'Isya': false,
          'isSubuhTepatWaktu': false,
          'createdAt': Timestamp.now(),
        };
      }


      dataHariIni[namaSholat] = true;


      if (namaSholat == 'Subuh') {
        dataHariIni['waktuSubuh'] = DateTime.now().toIso8601String();
        dataHariIni['isSubuhTepatWaktu'] = isTepatWaktu;
      }
      
      dataHariIni['lastUpdatedAt'] = Timestamp.now();

      await docRef.set(dataHariIni);
      print('Data checklist untuk $todayFormatted berhasil disimpan di Firestore.');
    } catch (e) {
      print('Error saving checklist: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan checklist: $e')),
        );
      }
    }
  }


  bool isDalamWaktu(String namaSholat) {
    final now = DateTime.now();
    final format = RegExp(r'^(\d+):(\d+)$');

    if (!waktuIbadah.containsKey(namaSholat)) return false;

    final matchAwal = format.firstMatch(waktuIbadah[namaSholat]![0])!;
    final matchAkhir = format.firstMatch(waktuIbadah[namaSholat]![1])!;

    final waktuAwal = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(matchAwal.group(1)!),
      int.parse(matchAwal.group(2)!),
    );
    var waktuAkhir = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(matchAkhir.group(1)!),
      int.parse(matchAkhir.group(2)!),
    );
    if (waktuAkhir.isBefore(waktuAwal)) {
      waktuAkhir = waktuAkhir.add(const Duration(days: 1));
    }

    if (namaSholat == 'Isya') {
      final isyaStart = DateTime(now.year, now.month, now.day, 19, 0);
      final nextDaySubuhEnd = DateTime(now.year, now.month, now.day, 4, 0).add(const Duration(days: 1));
      

      bool isDuringCurrentDayIsya = now.isAfter(isyaStart) && now.isBefore(DateTime(now.year, now.month, now.day, 23, 59, 59, 999));

      bool isDuringNextDayEarlyMorning = now.isAfter(DateTime(now.year, now.month, now.day, 0, 0)) && now.isBefore(nextDaySubuhEnd);

      if (isDuringCurrentDayIsya || isDuringNextDayEarlyMorning) {
        return true;
      }
      return false;
    }

    return now.isAfter(waktuAwal) && now.isBefore(waktuAkhir);
  }

  Future<void> _checkIbadah(String namaSholat) async {
    final now = DateTime.now();
    final format = RegExp(r'^(\d+):(\d+)$');
    


    if (namaSholat == 'Isya' && now.hour >= 0 && now.hour < 4) {

    } else {
      final matchAwal = format.firstMatch(waktuIbadah[namaSholat]![0])!;
      final waktuAwal = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(matchAwal.group(1)!),
        int.parse(matchAwal.group(2)!),
      );
      if (now.isBefore(waktuAwal)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Belum waktunya $namaSholat!")),
          );
        }
        return;
      }
    }

    final onTime = isDalamWaktu(namaSholat);
    

    await _simpanDataHarian(namaSholat, onTime);
    _updateUI();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            onTime
                ? '$namaSholat berhasil dicheck tepat waktu!'
                : '$namaSholat dicheck, tapi sudah lewat waktunya.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {


    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checklist Ibadah Harian"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: checklist.keys.map((namaSholat) {
          bool isChecked = checklist[namaSholat]!;
          bool isTepatWaktuDisplayed = false;
          if (namaSholat == 'Subuh') {
            isTepatWaktuDisplayed = _isSubuhTepatWaktuCurrent;
          }

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: isChecked ? Colors.deepPurple[50] : Colors.white, 
            child: ListTile(
              leading: Icon(
                Icons.check_circle,
                color: isChecked ? Colors.green : Colors.grey,
              ),
              title: Text(namaSholat),
              subtitle: isChecked
                  ? Text(
                      namaSholat == 'Subuh'
                          ? (isTepatWaktuDisplayed ? 'Tepat waktu' : 'Terlambat')
                          : 'Selesai',
                    )
                  : null,
              trailing: isChecked
                  ? const Icon(Icons.done, color: Colors.green)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                      ),
                      onPressed: () => _checkIbadah(namaSholat),
                      child: const Text(
                        "Check",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }
}