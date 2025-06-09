import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ibadah_harian_siswa/providers/QuranApiAuth.dart';
import 'package:ibadah_harian_siswa/screens/surah_detail_screen.dart';
import 'dart:convert';

class JuzDetailScreen extends StatefulWidget {
  final int juzNumber;
  final QuranApiAuth apiAuth;
  final String quranDataBaseUrl; 

  const JuzDetailScreen({
    super.key,
    required this.juzNumber,
    required this.apiAuth,
    required this.quranDataBaseUrl,
  });

  @override
  State<JuzDetailScreen> createState() => _JuzDetailScreenState();
}

class _JuzDetailScreenState extends State<JuzDetailScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> surahsInJuz = [];
  Map<String, List<Map<String, dynamic>>> versesBySurah = {};
  @override
  void initState() {
    super.initState();
    fetchJuzDetails();
  }
  Future<void> fetchJuzDetails() async {
    final dataUrl = '${widget.quranDataBaseUrl}/v1/juz/${widget.juzNumber}/verses';

    try {
      final response = await widget.apiAuth.authenticatedGet(dataUrl);

      if (response != null && response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Full Quran.Foundation API Response for Juz ${widget.juzNumber}: $data');
        if (data['data'] != null && data['data'] is List) {
          final List rawVerses = data['data'];
          Set<String> uniqueSurahNumbers = {};
          Map<String, List<Map<String, dynamic>>> tempVersesBySurah = {};

          for (var verseData in rawVerses) {

            String surahNumber = verseData['surah_number']?.toString() ?? '';
            String ayahNumber = verseData['ayah_number']?.toString() ?? '';
            String verseText = verseData['text']?.toString() ?? '';

            if (surahNumber.isNotEmpty && ayahNumber.isNotEmpty) {
              uniqueSurahNumbers.add(surahNumber);
              if (!tempVersesBySurah.containsKey(surahNumber)) {
                tempVersesBySurah[surahNumber] = [];
              }
              tempVersesBySurah[surahNumber]!.add({
                'ayah': ayahNumber,
                'text': verseText,
              });
            } else {
              print('Invalid verse data format: $verseData');
            }
          }

          List<Map<String, dynamic>> tempSurahs = uniqueSurahNumbers.map((surahNum) {
            return {
              'number': int.parse(surahNum),
              'name': 'Surah $surahNum', 
            };
          }).toList();

          tempSurahs.sort((a, b) => a['number'].compareTo(b['number']));

          setState(() {
            surahsInJuz = tempSurahs;
            versesBySurah = tempVersesBySurah;
            isLoading = false;
          });
        } else {
          print('Quran.Foundation API data format for juz is not a List or is null.');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print('❌ Gagal memuat data dari Quran.Foundation API: ${response?.statusCode ?? 'No response'}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching juz details from Quran.Foundation API: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Juz ${widget.juzNumber}'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : surahsInJuz.isEmpty
              ? const Center(child: Text('Tidak ada surah ditemukan di juz ini.'))
              : ListView.builder(
                  itemCount: surahsInJuz.length,
                  itemBuilder: (context, index) {
                    final surah = surahsInJuz[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(surah['name']),
                        subtitle: Text('Surah ke-${surah['number']}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SurahDetailScreen(
                                surahNumber: surah['number'],
                                surahName: surah['name'],
                                verses: versesBySurah[surah['number'].toString()] ?? [],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}