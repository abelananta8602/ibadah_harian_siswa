import 'package:flutter/material.dart';
import 'package:ibadah_harian_siswa/providers/QuranApiAuth.dart';
import 'package:ibadah_harian_siswa/screens/JuzDetailScreen.dart';
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  List<Map<String, dynamic>> juzList = [];
  bool isLoading = true;

  late QuranApiAuth _apiAuth;

  @override
  void initState() {
    super.initState();

    _apiAuth = QuranApiAuth(


      clientId: '7626698a-90a2-4524-9f44-2bffc93e3301',
      clientSecret: '2sVYYknsP7CaY~sXOT_8voWR_I',
          authEndpoint: 'https://oauth2.quran.foundation',
    );
    fetchJuz();
  }

  Future<void> fetchJuz() async {
    await Future.delayed(const Duration(milliseconds: 500));
    juzList = List.generate(30, (index) {
      return {
        'juz_number': index + 1,
        'start': {
          'surah': '',
          'ayah': '',
        }
      };
    });
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const String QURAN_DATA_BASE_URL = "https://api.quran.foundation";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Baca Al-Quran'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: juzList.length,
              itemBuilder: (context, index) {
                final juz = juzList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('Juz ${juz['juz_number']}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JuzDetailScreen(
                            juzNumber: juz['juz_number'],
                            apiAuth: _apiAuth,
                            quranDataBaseUrl: QURAN_DATA_BASE_URL,
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