import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_grok_vending/utils/constants.dart';
import 'package:app_grok_vending/screens/home_screen.dart';
import 'package:app_grok_vending/screens/add_card_screen.dart';
import 'package:app_grok_vending/screens/pay_nfc_screen.dart';
import 'package:app_grok_vending/screens/pay_qr_screen.dart';
import 'package:app_grok_vending/screens/load_balance_screen.dart';
import 'package:app_grok_vending/screens/login_screen.dart';
import 'package:app_grok_vending/screens/machine_login_screen.dart'; // <--- Adiciona este import
import 'package:app_grok_vending/models/product_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vending Wallet',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const MainScreen(),
        '/machine_login': (context) => const MachineLoginScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          // Utilizador já tem sessão → vai sempre para a tela intermédia de login na máquina
          return const MachineLoginScreen();
        }

        // Sem sessão → vai para login/registo normal
        return const LoginScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    const HomeScreen(),
    const AddCardScreen(),
    const PayNfcScreen(),
    const PayQrScreen(),
    const LoadBalanceScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Saldo'),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: 'Cartão'),
          BottomNavigationBarItem(icon: Icon(Icons.nfc), label: 'Pagar NFC'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'Pagar QR'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Carregar'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.cyan,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

// O teu AppState continua igual (não mexi)
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