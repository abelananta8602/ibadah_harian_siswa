import 'package:flutter/material.dart';
import '../data/app_data.dart';

class HadithListScreen extends StatelessWidget {
  const HadithListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kumpulan Hadits'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: AppData.allHadiths.isEmpty
          ? const Center(
              child: Text('Tidak ada data Hadits.'),
            )
          : ListView.builder(
              itemCount: AppData.allHadiths.length,
              itemBuilder: (context, index) {
                final hadith = AppData.allHadiths[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hadith.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        if (hadith.arabicText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              hadith.arabicText,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 20,
                                fontFamily: 'Amiri', 
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            hadith.translation,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        if (hadith.narrator.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Perawi: ${hadith.narrator}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}