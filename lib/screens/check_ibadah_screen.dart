import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

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

  Map<String, bool> tepatWaktu = {
    'Subuh': false,
    'Dzuhur': false,
    'Ashar': false,
    'Maghrib': false,
    'Isya': false,
  };

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
    _loadChecklist();
  }

  Future<void> _simpanRiwayatHarian() async {
    final prefs = await SharedPreferences.getInstance();
    final tanggal = DateTime.now().toIso8601String().split("T")[0];

    final dataHariIni = {'tanggal': tanggal, ...checklist};

    final String? jsonString = prefs.getString('riwayat_ibadah');
    List<dynamic> riwayat = jsonString != null ? json.decode(jsonString) : [];

    
    final existingIndex = riwayat.indexWhere(
      (item) => item['tanggal'] == tanggal,
    );
    if (existingIndex != -1) {
      riwayat[existingIndex] = dataHariIni;
    } else {
      riwayat.add(dataHariIni);
    }

    await prefs.setString('riwayat_ibadah', json.encode(riwayat));
  }

  Future<void> _loadChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      checklist.forEach((key, value) {
        checklist[key] = prefs.getBool('check_$key') ?? false;
        tepatWaktu[key] = prefs.getBool('ontime_$key') ?? false;
      });
    });
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

    if (now.isBefore(waktuAwal)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Belum waktunya $namaSholat!")));
      return;
    }

    final onTime = isDalamWaktu(namaSholat);

    setState(() {
      checklist[namaSholat] = true;
      tepatWaktu[namaSholat] = onTime;
    });

    await prefs.setBool('check_$namaSholat', true);
    await prefs.setBool('ontime_$namaSholat', onTime);
    await _simpanRiwayatHarian();

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
        children:
            checklist.keys.map((namaSholat) {
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.check_circle,
                    color: checklist[namaSholat]! ? Colors.green : Colors.grey,
                  ),
                  title: Text(namaSholat),
                  subtitle:
                      checklist[namaSholat]!
                          ? Text(
                            tepatWaktu[namaSholat]!
                                ? 'Tepat waktu'
                                : 'Terlambat',
                          )
                          : null,
                  trailing:
                      checklist[namaSholat]!
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
