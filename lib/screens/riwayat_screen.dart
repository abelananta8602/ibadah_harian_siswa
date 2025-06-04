import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _loadRiwayatData();
  }

  Future<void> _loadRiwayatData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('riwayat_ibadah');

    if (jsonString != null) {
      List<dynamic> decoded = json.decode(jsonString);
      riwayatList = decoded.cast<Map<String, dynamic>>();

      
      chartDataOverall = {
        "Subuh": 0, "Dzuhur": 0, "Ashar": 0, "Maghrib": 0, "Isya": 0,
      };

      
      for (var item in riwayatList) {
        for (var key in chartDataOverall.keys) {
          
          if (item.containsKey(key) && item[key] == true) {
            chartDataOverall[key] = chartDataOverall[key]! + 1;
          }
        }
      }
      _calculatePeriodData(); 
      setState(() {});
    } else {
      
      setState(() {
        riwayatList = [];
        chartDataOverall = {
          "Subuh": 0, "Dzuhur": 0, "Ashar": 0, "Maghrib": 0, "Isya": 0,
        };
        _dailyIbadahCount = {};
        _subuhConsistency = {};
      });
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
            
            if (item['Subuh'] == true) dailyTotal++;
            if (item['Dzuhur'] == true) dailyTotal++;
            if (item['Ashar'] == true) dailyTotal++;
            if (item['Maghrib'] == true) dailyTotal++;
            if (item['Isya'] == true) dailyTotal++;

            _dailyIbadahCount[formattedDate] = dailyTotal;

            
            if (item['Subuh'] == true && item['isSubuhTepatWaktu'] == true) {
              _subuhConsistency[formattedDate] = 1;
            } else {
              _subuhConsistency[formattedDate] = 0;
            }
          }
        } catch (e) {
          print("Error parsing date: $e");
        }
      }
    }
    _dailyIbadahCount = Map.fromEntries(_dailyIbadahCount.entries.toList()..sort((a, b) {
      DateTime dateA = DateFormat('dd MMM yyyy').parse('${a.key} ${now.year}');
      DateTime dateB = DateFormat('dd MMM yyyy').parse('${b.key} ${now.year}');
      return dateA.compareTo(dateB);
    }));

    _subuhConsistency = Map.fromEntries(_subuhConsistency.entries.toList()..sort((a, b) {
      DateTime dateA = DateFormat('dd MMM yyyy').parse('${a.key} ${now.year}');
      DateTime dateB = DateFormat('dd MMM yyyy').parse('${b.key} ${now.year}');
      return dateA.compareTo(dateB);
    }));

    setState(() {});
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Ibadah (Keseluruhan)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    selectedColor: Colors.deepPurple,
                    labelStyle: TextStyle(color: _selectedPeriod == ChartPeriod.weekly ? Colors.white : Colors.black),
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
                    selectedColor: Colors.deepPurple,
                    labelStyle: TextStyle(color: _selectedPeriod == ChartPeriod.monthly ? Colors.white : Colors.black),
                  ),
                ],
              ),
            ),

            
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Ibadah Harian (${_selectedPeriod == ChartPeriod.weekly ? 'Mingguan' : 'Bulanan'})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Konsistensi Subuh Tepat Waktu (${_selectedPeriod == ChartPeriod.weekly ? 'Mingguan' : 'Bulanan'})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }
}