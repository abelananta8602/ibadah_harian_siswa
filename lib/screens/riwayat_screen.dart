import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  Map<String, int> chartData = {
    "Subuh": 0,
    "Dzuhur": 0,
    "Ashar": 0,
    "Maghrib": 0,
    "Isya": 0,
  };

  List<Map<String, dynamic>> riwayatList = [];

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

      for (var item in riwayatList) {
        for (var key in chartData.keys) {
          if (item.containsKey(key) && item[key] == true) {
            chartData[key] = chartData[key]! + 1;
          }
        }
      }

      setState(() {});
    }
  }

  Widget _buildBarChart() {
    final List<BarChartGroupData> barGroups = [];
    int index = 0;
    chartData.forEach((key, value) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value.toDouble(),
              color: Colors.deepPurple,
              width: 16,
            ),
          ],
        ),
      );
      index++;
    });

    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final label = chartData.keys.elementAt(value.toInt());
                return Text(label, style: const TextStyle(fontSize: 12));
              },
            ),
          ),
        ),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildRiwayatList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: riwayatList.length,
      itemBuilder: (context, index) {
        final item = riwayatList[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: ListTile(
            title: Text(item['tanggal'] ?? 'Tanpa tanggal'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  chartData.keys.map((waktu) {
                    final bool? status = item[waktu];
                    return Text("$waktu: ${status == true ? '✅' : '❌'}");
                  }).toList(),
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
        title: const Text("Riwayat Ibadah"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Grafik Checklist",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 220,
              child: Padding(
                padding: EdgeInsets.only(top: 12), 
                child: _buildBarChart(),
              ),
            ),

            SizedBox(height: 220, child: _buildBarChart()),
            const SizedBox(height: 24),
            const Text(
              "Catatan Harian",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildRiwayatList(),
          ],
        ),
      ),
    );
  }
}
