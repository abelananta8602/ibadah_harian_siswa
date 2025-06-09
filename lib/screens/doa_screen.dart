import 'package:flutter/material.dart';
import 'dart:convert'; 
import 'package:flutter/services.dart' show rootBundle;

class Dua {
  final int id;
  final String title;
  final String arabic;
  final String latin;
  final String translation;

  Dua({
    required this.id,
    required this.title,
    required this.arabic,
    required this.latin,
    required this.translation,
  });

  factory Dua.fromJson(Map<String, dynamic> json) {
    return Dua(
      id: json['id'],
      title: json['title'],
      arabic: json['arabic'],
      latin: json['latin'],
      translation: json['translation'],
    );
  }
}

class DoaScreen extends StatefulWidget {
  const DoaScreen({super.key});

  @override
  State<DoaScreen> createState() => _DoaScreenState();
}

class _DoaScreenState extends State<DoaScreen> {
  List<Dua> _duas = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadDuas();
  }

  Future<void> _loadDuas() async {
    try {
      final String response = await rootBundle.loadString('assets/doas.json');
      final List<dynamic> data = jsonDecode(response);
      setState(() {
        _duas = data.map((json) => Dua.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat doa: ${e.toString()}';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $_error')),
        );
      }
      print("Error loading doas from assets: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doa Harian'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Text(
                    _error,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                )
              : _duas.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada doa ditemukan.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _duas.length,
                      itemBuilder: (context, index) {
                        final dua = _duas[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dua.title,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                                const Divider(height: 24, thickness: 1),
                                Text(
                                  dua.arabic,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontFamily: 'Amiri', 
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textDirection: TextDirection.rtl, 
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  dua.latin,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Terjemahan: ${dua.translation}',
                                  style: Theme.of(context).textTheme.bodyMedium,
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