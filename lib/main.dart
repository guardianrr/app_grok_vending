import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_grok_vending/utils/constants.dart';
import 'package:app_grok_vending/screens/home_screen.dart';
import 'package:app_grok_vending/screens/add_card_screen.dart';
import 'package:app_grok_vending/screens/pay_nfc_screen.dart';
import 'package:app_grok_vending/screens/pay_qr_screen.dart';
import 'package:app_grok_vending/screens/load_balance_screen.dart';
import 'package:app_grok_vending/screens/login_screen.dart';
import 'package:app_grok_vending/screens/login_instruction_screen.dart';   // <--- IMPORT ADICIONADO
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

        // MUDANÇA AQUI: agora vai para a tela de instrução após login
        if (snapshot.hasData) {
          return const LoginInstructionScreen();   // <--- ALTERADO
        }

        return const LoginScreen();
      },
    );
  }
}

// O resto do teu main.dart fica igual (MainScreen, AppState, etc.)
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

// AppState (mantém o teu, mas com saldo inicial 0 para teste)
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
        _createOrLoadUserData(user.uid);
      } else {
        _balance = 0.0;
        _cardId = '';
        _selectedProduct = null;
        notifyListeners();
      }
    });
  }

  Future<void> _createOrLoadUserData(String uid) async {
    final dbRef = FirebaseDatabase.instance.ref();
    final userRef = dbRef.child('users/$uid');

    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      await userRef.set({
        'saldo': 0.0,           // ←←← 0€ para teste (podes voltar a 50 depois)
        'cardId': '',
        'createdAt': DateTime.now().toIso8601String(),
      });
      _balance = 0.0;
      _cardId = '';
    } else {
      final data = snapshot.value as Map<dynamic, dynamic>?;
      _balance = (data?['saldo'] as num?)?.toDouble() ?? 0.0;
      _cardId = data?['cardId'] as String? ?? '';
    }
    notifyListeners();

    userRef.child('saldo').onValue.listen((event) {
      _balance = (event.snapshot.value as num?)?.toDouble() ?? 0.0;
      notifyListeners();
    });
  }

  // resto do AppState igual...
  void selectProduct(Product product) { _selectedProduct = product; notifyListeners(); }
  void clearSelectedProduct() { _selectedProduct = null; notifyListeners(); }
  void addBalance(double amount) { /* ... */ }
  void subtractBalance(double amount) { /* ... */ }
  void setCardId(String newId) { /* ... */ }
}