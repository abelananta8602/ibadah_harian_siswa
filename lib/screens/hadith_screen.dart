import 'package:flutter/material.dart';

class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baca Hadits'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_stories, size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                'Fitur Baca Hadits',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Bagian ini akan menampilkan koleksi Hadits. Anda bisa menggunakan API Hadits atau menyertakan Hadits pilihan dalam bentuk data lokal (misalnya JSON) di folder assets.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mencoba mengambil data Hadits dari API...')),
                  );
                },
                child: const Text('Cari Hadits (Contoh API)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}