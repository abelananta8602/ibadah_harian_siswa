import 'package:flutter/material.dart';
import 'package:ibadah_harian_siswa/screens/check_ibadah_screen.dart';
import 'package:ibadah_harian_siswa/screens/register.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ibadah Harian Siswa',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const DashboardScreen(),
        '/add_ibadah': (context) => const CheckIbadahScreen(),
      },
      home: FutureBuilder<bool>(
        future: checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Terjadi kesalahan saat mengambil data login.'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => runApp(const MyApp()),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return snapshot.data == true
                ? const DashboardScreen()
                : const LoginScreen();
          }
        },
      ),
    );
  }
}
