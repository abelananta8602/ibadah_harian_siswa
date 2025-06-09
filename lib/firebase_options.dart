

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBSZdSpTBWeHvzVT2grI2z6-sxmsP_ez_0',
    appId: '1:1082685091643:web:29e8e2ccbefbd77807911e',
    messagingSenderId: '1082685091643',
    projectId: 'ibadah-harian-siswa',
    authDomain: 'ibadah-harian-siswa.firebaseapp.com',
    storageBucket: 'ibadah-harian-siswa.firebasestorage.app',
    measurementId: 'G-TYF2Y8NDYN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDeQ3jQIlUnDnQf4TVgk8CKnz-McVqMG_E',
    appId: '1:1082685091643:android:5b388b23ba8ed80e07911e',
    messagingSenderId: '1082685091643',
    projectId: 'ibadah-harian-siswa',
    storageBucket: 'ibadah-harian-siswa.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCCC1KS_g2siwf7Lr0oA6jvCptEgaiSkOM',
    appId: '1:1082685091643:ios:1471b81248f466fa07911e',
    messagingSenderId: '1082685091643',
    projectId: 'ibadah-harian-siswa',
    storageBucket: 'ibadah-harian-siswa.firebasestorage.app',
    iosBundleId: 'com.example.ibadahHarianSiswa',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCCC1KS_g2siwf7Lr0oA6jvCptEgaiSkOM',
    appId: '1:1082685091643:ios:1471b81248f466fa07911e',
    messagingSenderId: '1082685091643',
    projectId: 'ibadah-harian-siswa',
    storageBucket: 'ibadah-harian-siswa.firebasestorage.app',
    iosBundleId: 'com.example.ibadahHarianSiswa',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBSZdSpTBWeHvzVT2grI2z6-sxmsP_ez_0',
    appId: '1:1082685091643:web:dbd0a0f70797000707911e',
    messagingSenderId: '1082685091643',
    projectId: 'ibadah-harian-siswa',
    authDomain: 'ibadah-harian-siswa.firebaseapp.com',
    storageBucket: 'ibadah-harian-siswa.firebasestorage.app',
    measurementId: 'G-59KLDH3M8N',
  );
}
