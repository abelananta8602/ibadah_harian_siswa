import 'package:flutter/material.dart';
import '../data/app_data.dart'; 
class DoaListScreen extends StatelessWidget {
  const DoaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doa Harian'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: AppData.allDoas.isEmpty
          ? const Center(
              child: Text('Tidak ada data Doa.'),
            )
          : ListView.builder(
              itemCount: AppData.allDoas.length,
              itemBuilder: (context, index) {
                final doa = AppData.allDoas[index];
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
                          doa.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        if (doa.arabicText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              doa.arabicText,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 20,
                                fontFamily: 'Amiri',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (doa.latinText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              doa.latinText,
                              style: TextStyle(
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            doa.translation,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        if (doa.source.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Sumber: ${doa.source}',
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