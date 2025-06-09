import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ibadah_harian_siswa/firebase_options.dart';
import 'package:ibadah_harian_siswa/screens/check_ibadah_screen.dart';
import 'package:ibadah_harian_siswa/screens/register.dart';
import 'package:ibadah_harian_siswa/screens/login_screen.dart';
import 'package:ibadah_harian_siswa/screens/dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:ibadah_harian_siswa/providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ibadah Harian Siswa',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const DashboardScreen(),
        '/add_ibadah': (context) => const CheckIbadahScreen(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData) {
            return const DashboardScreen();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
