import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math; 

class QiblatScreen extends StatefulWidget {
  const QiblatScreen({super.key});

  @override
  State<QiblatScreen> createState() => _QiblatScreenState();
}

class _QiblatScreenState extends State<QiblatScreen> {
  double? _heading; 
  double? _qiblaDirection; 
  String _locationStatus = 'Mencari lokasi...';
  @override
  void initState() {
    super.initState();
    _checkLocationAndStartCompass();
  }

  Future<void> _checkLocationAndStartCompass() async {
    bool serviceEnabled;
    LocationPermission permission;


    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _locationStatus = 'Layanan lokasi tidak diaktifkan. Mohon aktifkan.';
        });
      }

      return; 
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _locationStatus = 'Izin lokasi ditolak.';
          });
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _locationStatus = 'Izin lokasi ditolak permanen. Mohon izinkan secara manual di pengaturan aplikasi.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _locationStatus = 'Mendapatkan lokasi...';
      });
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), 
      );
      if (mounted) {
        setState(() {
          _locationStatus = 'Lokasi ditemukan. Menghitung arah Kiblat...';
        });
      }
      _calculateQibla(position.latitude, position.longitude);
      _startCompass();
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationStatus = 'Gagal mendapatkan lokasi: ${e.toString()}. Coba lagi atau pastikan GPS aktif.';
        });
      }
      print("Error getting location: $e");
    }
  }

  void _startCompass() {

    FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        setState(() {

          if (event.heading != null) {
            _heading = event.heading;
          }
        });
      }
    });
  }


  void _calculateQibla(double lat, double lon) {

    const double kaabaLat = 21.4225;
    const double kaabaLon = 39.8262;

    double dLat = (kaabaLat - lat) * math.pi / 180;
    double dLon = (kaabaLon - lon) * math.pi / 180;

    double latRad = lat * math.pi / 180;
    double kaabaLatRad = kaabaLat * math.pi / 180;

    double y = math.sin(dLon) * math.cos(kaabaLatRad);
    double x = math.cos(latRad) * math.sin(kaabaLatRad) -
        math.sin(latRad) * math.cos(kaabaLatRad) * math.cos(dLon);
    double qibla = math.atan2(y, x) * 180 / math.pi;

    if (mounted) {
      setState(() {
        _qiblaDirection = (qibla + 360) % 360; 
        _locationStatus = 'Arah Kiblat siap!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arah Kiblat'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_qiblaDirection == null || _heading == null) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                _locationStatus,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_locationStatus.contains('Izin lokasi ditolak') || _locationStatus.contains('Layanan lokasi tidak diaktifkan'))
                ElevatedButton(
                  onPressed: () {

                    Geolocator.openAppSettings().then((value) {
                      if (value) {

                        _checkLocationAndStartCompass();
                      }
                    });
                  },
                  child: const Text('Buka Pengaturan Lokasi'),
                ),
            ] else ...[
              Text(
                'Arah Kompas: ${_heading!.toStringAsFixed(2)}°',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Arah Kiblat (dari Utara): ${_qiblaDirection!.toStringAsFixed(2)}°',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
              const SizedBox(height: 40),

              Transform.rotate(
                angle: ((_heading ?? 0) * (math.pi / 180) * -1), 
                alignment: Alignment.center,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [

                      Positioned(
                        top: 20,
                        child: Text(
                          'N',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 8,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.red, 
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),


                      Transform.rotate(
                        angle: ((_qiblaDirection! - (_heading ?? 0)) * (math.pi / 180)),
                        alignment: Alignment.center,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 6,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      Icon(Icons.location_on, size: 28, color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Arah kiblat akan ditunjukkan oleh jarum hijau. Pastikan perangkat Anda kalibrasi dengan baik.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}