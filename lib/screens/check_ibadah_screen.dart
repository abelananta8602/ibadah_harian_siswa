import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    _loadChecklistForToday();
  }

  void _updateUI() {
    _loadChecklistForToday();
  }

  Future<void> _loadChecklistForToday() async {
    final prefs = await SharedPreferences.getInstance();
    final todayFormatted = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String? allRiwayatJson = prefs.getString('riwayat_ibadah');

    List<Map<String, dynamic>> allRiwayat = [];
    if (allRiwayatJson != null) {
      allRiwayat = (json.decode(allRiwayatJson) as List)
          .cast<Map<String, dynamic>>();
    }

    Map<String, dynamic>? dataHariIni;
    for (var item in allRiwayat) {
      if (item['tanggal'] == todayFormatted) {
        dataHariIni = item;
        break;
      }
    }

    setState(() {
      if (dataHariIni != null) {
        checklist.forEach((key, value) {
          checklist[key] = dataHariIni![key] ?? false;
        });
        _isSubuhTepatWaktuCurrent = dataHariIni!['isSubuhTepatWaktu'] ?? false;
      } else {
        checklist.updateAll((key, value) => false);
        _isSubuhTepatWaktuCurrent = false;
      }
    });
  }

  Future<void> _simpanDataHarian(String namaSholat, bool isTepatWaktu) async {
    final prefs = await SharedPreferences.getInstance();
    final todayFormatted = DateFormat('yyyy-MM-dd').format(DateTime.now());

    String? allRiwayatJson = prefs.getString('riwayat_ibadah');
    List<Map<String, dynamic>> allRiwayat = [];
    if (allRiwayatJson != null) {
      allRiwayat = (json.decode(allRiwayatJson) as List)
          .cast<Map<String, dynamic>>();
    }

    int? todayIndex;
    for (int i = 0; i < allRiwayat.length; i++) {
      if (allRiwayat[i]['tanggal'] == todayFormatted) {
        todayIndex = i;
        break;
      }
    }

    Map<String, dynamic> dataHariIni = {};
    if (todayIndex != null) {
      dataHariIni = allRiwayat[todayIndex];
    } else {
      dataHariIni = {
        'tanggal': todayFormatted,
        'Subuh': false,
        'Dzuhur': false,
        'Ashar': false,
        'Maghrib': false,
        'Isya': false,
        'isSubuhTepatWaktu': false,
      };
    }

    dataHariIni[namaSholat] = true;

    if (namaSholat == 'Subuh') {
      dataHariIni['waktuSubuh'] = DateTime.now().toIso8601String();
      dataHariIni['isSubuhTepatWaktu'] = isTepatWaktu;
    }

    if (todayIndex != null) {
      allRiwayat[todayIndex] = dataHariIni;
    } else {
      allRiwayat.add(dataHariIni);
    }

    allRiwayat.sort((a, b) => a['tanggal'].compareTo(b['tanggal']));

    await prefs.setString('riwayat_ibadah', json.encode(allRiwayat));
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
    if (namaSholat == 'Isya' && now.isBefore(waktuAwal) && now.hour < 6) {
        final yesterdayWaktuAwal = waktuAwal.subtract(const Duration(days: 1));
        if (now.isAfter(yesterdayWaktuAwal) && now.isBefore(waktuAkhir)) {
            return true;
        }
    }
    return now.isAfter(waktuAwal) && now.isBefore(waktuAkhir);
  }

  Future<void> _checkIbadah(String namaSholat) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final format = RegExp(r'^(\d+):(\d+)$');
    final matchAwal = format.firstMatch(waktuIbadah[namaSholat]![0])!;
    final waktuAwal = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(matchAwal.group(1)!),
      int.parse(matchAwal.group(2)!),
    );
    if (now.isBefore(waktuAwal) && !(namaSholat == 'Isya' && now.hour < 6)) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Belum waktunya $namaSholat!"))
        );
        return;
    }
    final onTime = isDalamWaktu(namaSholat);
    await _simpanDataHarian(namaSholat, onTime);
    _updateUI(); 

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

  @override
  Widget build(BuildContext context) {
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