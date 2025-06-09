import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart'; 
class FileSaver {
  static Future<void> saveFile(
      Uint8List bytes, String filename, BuildContext context) async {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$filename berhasil diunduh!')),
    );
  }
}