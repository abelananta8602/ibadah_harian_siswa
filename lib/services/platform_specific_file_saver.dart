
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ibadah_harian_siswa/services/file_saver_non_web.dart'
    if (dart.library.html) 'package:ibadah_harian_siswa/services/file_saver_web.dart';


class PlatformSpecificFileSaver {
  static Future<void> save(Uint8List bytes, String filename, BuildContext context) {
    return FileSaver.saveFile(bytes, filename, context);
  }
}