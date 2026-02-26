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
import 'package:app_grok_vending/screens/login_instruction_screen.dart';
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

        if (snapshot.hasData) {
          return const LoginInstructionScreen();
        }

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

class AppState extends ChangeNotifier {
  double _balance = 0.0;
  String _cardId = '';
  String _name = 'Utilizador'; // Nome do utilizador (default)
  Product? _selectedProduct;

  double get balance => _balance;
  String get cardId => _cardId;
  String get name => _name; // Getter para o nome (isto resolve o erro!)
  Product? get selectedProduct => _selectedProduct;

  AppState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _createOrLoadUserData(user.uid);
      } else {
        _balance = 0.0;
        _cardId = '';
        _name = 'Utilizador';
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
        'saldo': 0.0,
        'cardId': '',
        'name': 'Utilizador', // Nome default ao criar conta
        'createdAt': DateTime.now().toIso8601String(),
      });
      _balance = 0.0;
      _cardId = '';
      _name = 'Utilizador';
    } else {
      final data = snapshot.value as Map<dynamic, dynamic>?;
      _balance = (data?['saldo'] as num?)?.toDouble() ?? 0.0;
      _cardId = data?['cardId'] as String? ?? '';
      _name = data?['name'] as String? ?? 'Utilizador';
    }

    notifyListeners();

    // Listener em tempo real para saldo
    userRef.child('saldo').onValue.listen((event) {
      _balance = (event.snapshot.value as num?)?.toDouble() ?? 0.0;
      notifyListeners();
      print("Saldo sincronizado da DB em tempo real: $_balance");
    });

    // Listener em tempo real para nome
    userRef.child('name').onValue.listen((event) {
      _name = event.snapshot.value as String? ?? 'Utilizador';
      notifyListeners();
      print("Nome sincronizado da DB: $_name");
    });
  }

  void selectProduct(Product product) {
    _selectedProduct = product;
    notifyListeners();
  }

  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }

  Future<void> addBalance(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Erro: Nenhum utilizador logado ao tentar adicionar saldo");
      return;
    }

    _balance += amount;
    notifyListeners();

    try {
      await FirebaseDatabase.instance
          .ref('users/${user.uid}/saldo')
          .set(_balance);
      print("Saldo adicionado na DB: $amount | Novo total: $_balance");
    } catch (e) {
      print("Erro ao adicionar saldo na DB: $e");
      _balance -= amount; // Reverte localmente se falhar
      notifyListeners();
    }
  }

  Future<void> subtractBalance(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_balance >= amount) {
      _balance -= amount;
      notifyListeners();

      try {
        await FirebaseDatabase.instance
            .ref('users/${user.uid}/saldo')
            .set(_balance);
        print("Saldo subtraído na DB: $amount | Novo total: $_balance");
      } catch (e) {
        print("Erro ao subtrair saldo na DB: $e");
        _balance += amount; // Reverte
        notifyListeners();
      }
    }
  }

  Future<void> setCardId(String newId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _cardId = newId.trim();
    notifyListeners();

    try {
      await FirebaseDatabase.instance
          .ref('users/${user.uid}/cardId')
          .set(_cardId);
      print("CardId atualizado na DB: $_cardId");
    } catch (e) {
      print("Erro ao atualizar cardId na DB: $e");
    }
  }
}