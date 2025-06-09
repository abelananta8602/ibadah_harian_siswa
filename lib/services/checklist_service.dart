import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class ChecklistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<void> migrateChecklistFromSharedPreferences() async {
    final user = _auth.currentUser;
    if (user == null) {
      print("User not logged in, cannot migrate data.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? allRiwayatJson = prefs.getString('riwayat_ibadah');

    if (allRiwayatJson == null || allRiwayatJson.isEmpty) {
      print("No old checklist data found in Shared Preferences.");
      return;
    }

    try {
      List<Map<String, dynamic>> allRiwayat = (json.decode(allRiwayatJson) as List)
          .cast<Map<String, dynamic>>();



      final userDocRef = _firestore.collection('users').doc(user.uid);
      DocumentSnapshot userDoc = await userDocRef.get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null && userData['migratedOldChecklist'] == true) {
        print("Old checklist data already migrated for this user. Skipping.");


        return;
      }

      WriteBatch batch = _firestore.batch();
      
      print("Starting migration of old checklist data to Firestore...");

      for (var item in allRiwayat) {
        String tanggal = item['tanggal'];
        Map<String, dynamic> dataToSave = Map<String, dynamic>.from(item);


        dataToSave.remove('tanggal'); 
        

        dataToSave.putIfAbsent('Subuh', () => false);
        dataToSave.putIfAbsent('Dzuhur', () => false);
        dataToSave.putIfAbsent('Ashar', () => false);
        dataToSave.putIfAbsent('Maghrib', () => false);
        dataToSave.putIfAbsent('Isya', () => false);
        dataToSave.putIfAbsent('isSubuhTepatWaktu', () => false);


        dataToSave.putIfAbsent('createdAt', () => Timestamp.now());
        dataToSave.putIfAbsent('lastUpdatedAt', () => Timestamp.now());


        if (dataToSave.containsKey('waktuSubuh') && dataToSave['waktuSubuh'] is String) {
          try {
            dataToSave['waktuSubuh'] = DateTime.parse(dataToSave['waktuSubuh']);
          } catch (e) {
            print("Warning: Could not parse waktuSubuh for $tanggal. Keeping as string. $e");

          }
        }


        batch.set(
          _firestore.collection('users').doc(user.uid).collection('checklists').doc(tanggal),
          dataToSave,
        );
      }


      batch.update(userDocRef, {'migratedOldChecklist': true});

      await batch.commit();
      print("Migration complete. All old checklist data saved to Firestore.");


      await prefs.remove('riwayat_ibadah');
      print("Old checklist data cleared from Shared Preferences.");

    } catch (e) {
      print("Error migrating old checklist data: $e");

    }
  }


  Future<void> saveChecklistData(String userId, String tanggal, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('checklists')
        .doc(tanggal)
        .set(data, SetOptions(merge: true));
  }


  Stream<DocumentSnapshot> getChecklistDataForToday(String userId, String tanggal) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('checklists')
        .doc(tanggal)
        .snapshots();
  }
}