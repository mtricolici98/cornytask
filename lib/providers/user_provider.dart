import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  int _coins = 0; // Local state for coins
  bool _firstLogin = false; // Local state for coins
  FirebaseAuth _auth = FirebaseAuth.instance;

  int get coins => _coins;
  bool get firstLogin => _firstLogin;

  // Method to load user data from Firestore
  Future<void> loadUserData() async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        // Handle the case where user is not logged in (e.g., prompt for login)
        return;
      }

      // Get user document from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        _coins = userDoc['coins']; // Load coins from Firestore
        _firstLogin = userDoc['firstLogin']; // Load coins from Firestore
      } else {
        // Initialize user data if document doesn't exist
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'coins': 0, // Default coins for new user
          'firstLogin': false,
        });
        _firstLogin = true;
        _coins = 0;
      }
      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Method to spend coins
  void spendCoins(int amount) async {
    if (_coins >= amount) {
      _coins -= amount;
      if (_coins < 0){
        _coins = 0;
      }
      // Update Firestore
      final user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'coins': _coins, // Update the coins field in Firestore
        });
      }
      notifyListeners();
    }
  }

  // Method to add coins
  void addCoins(int amount) async {
    _coins += amount;
    // Update Firestore
    final user = _auth.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'coins': _coins, // Update the coins field in Firestore
      });
    }
    notifyListeners();
  }
}
