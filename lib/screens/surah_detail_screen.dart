import 'package:flutter/material.dart';

class SurahDetailScreen extends StatelessWidget {
  final int surahNumber;
  final String surahName;
  final List<Map<String, dynamic>> verses;

  const SurahDetailScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
    required this.verses,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(surahName),
      ),
      body: verses.isEmpty
          ? const Center(child: Text('Tidak ada ayat ditemukan untuk surah ini.'))
          : ListView.builder(
              itemCount: verses.length,
              itemBuilder: (context, index) {
                final verse = verses[index];
                return ListTile(
                  title: Text(
                    verse['text'] ?? '',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 20),
                  ),
                  subtitle: Text(
                    'Ayat ${verse['ayah']}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              },
            ),
    );
  }
}