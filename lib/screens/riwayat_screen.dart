import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ibadah_harian_siswa/services/platform_specific_file_saver.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});
  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}
enum ChartPeriod { weekly, monthly }
class _RiwayatScreenState extends State<RiwayatScreen> {
  Map<String, int> chartDataOverall = {
    "Subuh": 0,
    "Dzuhur": 0,
    "Ashar": 0,
    "Maghrib": 0,
    "Isya": 0,
  };
  List<Map<String, dynamic>> riwayatList = [];
  ChartPeriod _selectedPeriod = ChartPeriod.weekly;
  Map<String, int> _dailyIbadahCount = {};
  Map<String, int> _subuhConsistency = {};
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId;
  @override
  void initState() {
    super.initState();

    _currentUserId = _auth.currentUser?.uid;
    if (_currentUserId != null) {
      _loadRiwayatData();
    } else {

      print("User not logged in or UID not available.");

    }
  }
  Future<void> _loadRiwayatData() async {
    if (_currentUserId == null) return; 
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('checklists')
          .orderBy('tanggal', descending: true).get();
      riwayatList.clear();
      chartDataOverall = {
        "Subuh": 0,
        "Dzuhur": 0,
        "Ashar": 0,
        "Maghrib": 0,
        "Isya": 0,
      };
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();
        riwayatList.add(data);
        for (var key in chartDataOverall.keys) {
          if (data.containsKey(key) && data[key] == true) {
            chartDataOverall[key] = chartDataOverall[key]! + 1;
          }
        }
      }
      _calculatePeriodData();

      setState(() {});
    } catch (e) {
      print("Error loading riwayat data from Firestore: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat riwayat: ${e.toString()}')),
      );
    }
  }

  void _calculatePeriodData() {
    _dailyIbadahCount = {};
    _subuhConsistency = {};

    DateTime now = DateTime.now();
    DateTime startDate;

    if (_selectedPeriod == ChartPeriod.weekly) {

      startDate = now.subtract(Duration(days: now.weekday - 1));
      startDate = DateTime(startDate.year, startDate.month, startDate.day);
    } else {

      startDate = DateTime(now.year, now.month, 1);
    }
    for (int i = 0; i <= now.difference(startDate).inDays; i++) {
      DateTime currentDate = startDate.add(Duration(days: i));
      String formattedDate = DateFormat('dd MMM').format(currentDate);
      _dailyIbadahCount.putIfAbsent(formattedDate, () => 0);
      _subuhConsistency.putIfAbsent(formattedDate, () => 0);
    }

    for (var item in riwayatList) {
      String? dateString = item['tanggal'];
      if (dateString != null) {
        try {
          DateTime itemDate = DateFormat('yyyy-MM-dd').parse(dateString);
          if (itemDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
              itemDate.isBefore(now.add(const Duration(days: 1)))) {
            String formattedDate = DateFormat('dd MMM').format(itemDate);
            int dailyTotal = 0;
            if (item.containsKey('Subuh') && item['Subuh'] == true) dailyTotal++;
            if (item.containsKey('Dzuhur') && item['Dzuhur'] == true) dailyTotal++;
            if (item.containsKey('Ashar') && item['Ashar'] == true) dailyTotal++;
            if (item.containsKey('Maghrib') && item['Maghrib'] == true) dailyTotal++;
            if (item.containsKey('Isya') && item['Isya'] == true) dailyTotal++;
            _dailyIbadahCount[formattedDate] = dailyTotal;
            if (item.containsKey('Subuh') && item['Subuh'] == true &&
                item.containsKey('isSubuhTepatWaktu') && item['isSubuhTepatWaktu'] == true) {
              _subuhConsistency[formattedDate] = 1;
            } else {
              _subuhConsistency[formattedDate] = 0;
            }
          }
        } catch (e) {
          print("Error parsing date in _calculatePeriodData: $e");
        }
      }
    }
    _dailyIbadahCount = Map.fromEntries(_dailyIbadahCount.entries.toList()..sort((a, b) {
      DateTime dateA = DateFormat('dd MMM').parse('${a.key} ${now.year}');
      DateTime dateB = DateFormat('dd MMM').parse('${b.key} ${now.year}');
      return dateA.compareTo(dateB);
    }));

    _subuhConsistency = Map.fromEntries(_subuhConsistency.entries.toList()..sort((a, b) {
      DateTime dateA = DateFormat('dd MMM').parse('${a.key} ${now.year}');
      DateTime dateB = DateFormat('dd MMM').parse('${b.key} ${now.year}');
      return dateA.compareTo(dateB);
    }));

    setState(() {});
  }

 Future<void> generateAndSavePdf(
    List<Map<String, dynamic>> riwayatList,
    Map<String, int> dailyIbadahCount,
    Map<String, int> subuhConsistency) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return [
          pw.Center(
            child: pw.Text(
              'Laporan Ibadah Harian Siswa',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Ringkasan Data Ibadah:'),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Tanggal', 'Sholat Wajib', 'Subuh Tepat Waktu'],
            data: dailyIbadahCount.entries.map((entry) {
              String date = entry.key;
              int ibadahCount = entry.value;
              int subuhConsistent = subuhConsistency[date] ?? 0;
              return [date, ibadahCount.toString(), subuhConsistent == 1 ? 'Ya' : 'Tidak'];
            }).toList(),
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(4),
          ),
          pw.SizedBox(height: 20),

          pw.Text('Detail Riwayat Ibadah:'),
          pw.SizedBox(height: 10),
          ...riwayatList.map((item) {
            return pw.Text(
              '${item.containsKey('tanggal') ? item['tanggal'] : 'Tanggal Tidak Tersedia'}: '
              'Subuh: ${item.containsKey('Subuh') && item['Subuh'] == true ? 'V' : 'X'}, '
              'Dzuhur: ${item.containsKey('Dzuhur') && item['Dzuhur'] == true ? 'V' : 'X'}, '
              'Ashar: ${item.containsKey('Ashar') && item['Ashar'] == true ? 'V' : 'X'}, '
              'Maghrib: ${item.containsKey('Maghrib') && item['Maghrib'] == true ? 'V' : 'X'}, '
              'Isya: ${item.containsKey('Isya') && item['Isya'] == true ? 'V' : 'X'} '
              '(Subuh Tepat Waktu: ${item.containsKey('isSubuhTepatWaktu') && item['isSubuhTepatWaktu'] == true ? 'Ya' : 'Tidak'})',
              style: const pw.TextStyle(fontSize: 10),
            );
          }).toList(),
        ];
      },
    ),
  );

  final String filename = 'laporan_ibadah_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';


  try {
    final bytes = await pdf.save();

    await PlatformSpecificFileSaver.save(bytes, filename, context);
  } catch (e) {
    print('Error generating PDF: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Terjadi kesalahan saat membuat PDF: ${e.toString()}')),
    );
  }
}

Future<void> generateAndSaveCsv(
    List<Map<String, dynamic>> riwayatList,
    Map<String, int> dailyIbadahCount,
    Map<String, int> subuhConsistency) async {
  StringBuffer csvContent = StringBuffer();

  csvContent.writeln('Tanggal,Total Ibadah Wajib,Subuh Tepat Waktu');
  dailyIbadahCount.forEach((date, ibadahCount) {
    int subuhConsistent = subuhConsistency[date] ?? 0;
    String subuhStatus = subuhConsistent == 1 ? 'Ya' : 'Tidak';
    csvContent.writeln('$date,$ibadahCount,$subuhStatus');
  });

  csvContent.writeln('\nDetail Riwayat Ibadah:');
  csvContent.writeln('Tanggal,Subuh,Dzuhur,Ashar,Maghrib,Isya,Subuh Tepat Waktu');

  for (var item in riwayatList) {
    csvContent.writeln(
        '${item.containsKey('tanggal') ? item['tanggal'] : 'Tanggal Tidak Tersedia'},'
        '${item.containsKey('Subuh') && item['Subuh'] == true ? 'V' : 'X'},'
        '${item.containsKey('Dzuhur') && item['Dzuhur'] == true ? 'V' : 'X'},'
        '${item.containsKey('Ashar') && item['Ashar'] == true ? 'V' : 'X'},'
        '${item.containsKey('Maghrib') && item['Maghrib'] == true ? 'V' : 'X'},'
        '${item.containsKey('Isya') && item['Isya'] == true ? 'V' : 'X'},'
        '${item.containsKey('isSubuhTepatWaktu') && item['isSubuhTepatWaktu'] == true ? 'Ya' : 'Tidak'}');
  }

  final String filename = 'laporan_ibadah_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';


  try {
    final bytes = utf8.encode(csvContent.toString()); 

    await PlatformSpecificFileSaver.save(bytes, filename, context);
  } catch (e) {
    print('Error generating CSV: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Terjadi kesalahan saat membuat CSV: ${e.toString()}')),
    );
  }
}

  Widget _buildBarChart() {
    final List<BarChartGroupData> barGroups = [];
    int index = 0;
    chartDataOverall.forEach((key, value) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value.toDouble(),
              color: Colors.deepPurple,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
      index++;
    });

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: chartDataOverall.values.isEmpty ? 5 : (chartDataOverall.values.reduce((a, b) => a > b ? a : b) + 1).toDouble(),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                },
                reservedSize: 28,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final label = chartDataOverall.keys.elementAt(value.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(label, style: const TextStyle(fontSize: 12)),
                  );
                },
                reservedSize: 40,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: barGroups,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (BarChartGroupData group) {
                return Colors.blueGrey;
              },
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String sholatName = chartDataOverall.keys.elementAt(group.x.toInt());
                return BarTooltipItem(
                  '$sholatName\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: <TextSpan>[
                    TextSpan(
                      text: rod.toY.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyLineChart(Map<String, int> data, String title) {
    if (data.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text("Tidak ada data untuk periode ini.", style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    final List<FlSpot> spots = [];
    final List<String> labels = data.keys.toList();

    for (int i = 0; i < labels.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[labels[i]]!.toDouble()));
    }

    double maxY = spots.map((spot) => spot.y).fold(0.0, (prev, element) => prev > element ? prev : element);
    maxY = (maxY < 1) ? 1 : (maxY + 0.5).ceilToDouble();

    return AspectRatio(
      aspectRatio: 1.5,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: true, horizontalInterval: 1),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(labels[index], style: const TextStyle(fontSize: 10)),
                    );
                  }
                  return const Text('');
                },
                interval: 1.0,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                },
                reservedSize: 28,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
          minX: 0,
          maxX: (labels.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.deepPurple,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Ibadah'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Membuat laporan PDF...')),
              );
              await generateAndSavePdf(
                riwayatList,
                _dailyIbadahCount,
                _subuhConsistency,
              );
            },
            tooltip: 'Export ke PDF',
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Membuat laporan CSV...')),
              );
              await generateAndSaveCsv(
                riwayatList,
                _dailyIbadahCount,
                _subuhConsistency,
              );
            },
            tooltip: 'Export ke Excel (CSV)',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Ibadah (Keseluruhan)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildBarChart(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ChoiceChip(
                    label: const Text('Mingguan'),
                    selected: _selectedPeriod == ChartPeriod.weekly,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPeriod = ChartPeriod.weekly;
                          _calculatePeriodData();
                        });
                      }
                    },
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                        color: _selectedPeriod == ChartPeriod.weekly ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('Bulanan'),
                    selected: _selectedPeriod == ChartPeriod.monthly,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPeriod = ChartPeriod.monthly;
                          _calculatePeriodData();
                        });
                      }
                    },
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                        color: _selectedPeriod == ChartPeriod.monthly ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Ibadah Harian (${_selectedPeriod == ChartPeriod.weekly ? 'Mingguan' : 'Bulanan'})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: _buildDailyLineChart(_dailyIbadahCount, 'Total Ibadah Harian'),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Konsistensi Subuh Tepat Waktu (${_selectedPeriod == ChartPeriod.weekly ? 'Mingguan' : 'Bulanan'})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: _buildDailyLineChart(_subuhConsistency, 'Konsistensi Subuh'),
                    ),
                  ],
                ),
              ),
            ),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Catatan Harian",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRiwayatList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatList() {
    if (riwayatList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Tidak ada riwayat ibadah untuk ditampilkan.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: riwayatList.length,
      itemBuilder: (context, index) {
        final item = riwayatList[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          color: Theme.of(context).cardColor,
          child: ListTile(
            title: Text(
              item.containsKey('tanggal') ? item['tanggal'] : 'Tanggal Tidak Tersedia',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  chartDataOverall.keys.map((waktu) {
                    final bool? status = item.containsKey(waktu) ? item[waktu] : false;
                    return Text(
                      "$waktu: ${status == true ? '✅' : '❌'}",
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );
  }
}