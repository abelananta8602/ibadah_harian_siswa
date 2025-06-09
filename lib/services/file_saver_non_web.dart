import 'dart:io'; 
import 'dart:typed_data';
import 'package:flutter/material.dart'; 
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class FileSaver {
  static Future<void> saveFile(
      Uint8List bytes, String filename, BuildContext context) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String path = '${directory.path}/$filename';
      final file = File(path);
      await file.writeAsBytes(bytes);

      if (await file.exists()) {
        await OpenFilex.open(path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$filename berhasil dibuat dan dibuka!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan file.')),
        );
      }
    } catch (e) {
      print('Error saving file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan saat menyimpan file: ${e.toString()}')),
      );
    }
  }
}