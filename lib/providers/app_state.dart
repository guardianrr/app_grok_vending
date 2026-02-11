import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_grok_vending/models/product_model.dart';

class AppState extends ChangeNotifier {
  double _balance = 0.0;
  String _cardId = '';
  Product? _selectedProduct;

  double get balance => _balance;
  String get cardId => _cardId;
  Product? get selectedProduct => _selectedProduct;

  AppState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _balance = 0.0;
        _cardId = '';
        _selectedProduct = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      _balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
      _cardId = data['cardId'] as String? ?? '';
    } else {
      _balance = 50.0;
      _cardId = '';
      await _saveUserData(uid);
    }
    notifyListeners();
  }

  Future<void> _saveUserData(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'balance': _balance,
      'cardId': _cardId,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void selectProduct(Product product) {
    _selectedProduct = product;
    notifyListeners();
  }

  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }

  void addBalance(double amount) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _balance += amount;
    notifyListeners();
    _saveUserData(user.uid);
  }

  void subtractBalance(double amount) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_balance >= amount) {
      _balance -= amount;
      notifyListeners();
      _saveUserData(user.uid);
    }
  }

  void setCardId(String newId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _cardId = newId.trim();
    notifyListeners();
    _saveUserData(user.uid);
  }
}