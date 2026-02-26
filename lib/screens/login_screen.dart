import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_grok_vending/screens/login_instruction_screen.dart';
import 'package:app_grok_vending/utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomeController = TextEditingController();
  bool _lembrarMe = false;
  bool _isLoading = false;
  bool _isRegisto = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _verificarLembrarMe();
  }

  Future<void> _verificarLembrarMe() async {
    final prefs = await SharedPreferences.getInstance();
    final lembrar = prefs.getBool('lembrar_me') ?? false;

    if (lembrar && FirebaseAuth.instance.currentUser != null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginInstructionScreen()),
      );
    }
  }

  Future<void> _iniciarSessaoComEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('lembrar_me', _lembrarMe);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginInstructionScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          'user-not-found' => 'Utilizador não encontrado.',
          'wrong-password' => 'Palavra-passe incorreta.',
          'invalid-email' => 'Email inválido.',
          _ => 'Erro: ${e.message ?? "Erro desconhecido"}',
        };
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro inesperado: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registarComEmail() async {
    if (_nomeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Insira o seu nome para continuar';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user != null) {
        final nomeCompleto = _nomeController.text.trim();
        final primeiroNome = nomeCompleto.split(' ').first;

        await FirebaseDatabase.instance.ref('users/${user.uid}').set({
          'name': primeiroNome,
          'saldo': 0.0,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('lembrar_me', _lembrarMe);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginInstructionScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          'weak-password' => 'A palavra-passe deve ter pelo menos 6 caracteres.',
          'email-already-in-use' => 'Este email já está registado.',
          'invalid-email' => 'Email inválido.',
          _ => 'Erro: ${e.message ?? "Erro desconhecido"}',
        };
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro inesperado: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _iniciarSessaoComGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final nomeGoogle = googleUser.displayName ?? 'Utilizador';
        final primeiroNome = nomeGoogle.split(' ').first;

        final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
        final snapshot = await userRef.get();
        if (!snapshot.exists) {
          await userRef.set({
            'name': primeiroNome,
            'saldo': 0.0,
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('lembrar_me', true);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginInstructionScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao entrar com Google: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recuperarPalavraPasse() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Insira o seu email para recuperar a palavra-passe';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email de recuperação enviado! Verifique a sua caixa de entrada.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar email: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Logo da tua app (espaço reservado)
                Image.asset(
                  'assets/images/products/logo_tapngo.png',
                  height: 80,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image_not_supported, size: 80, color: Colors.grey);
                  },
                ),
                const SizedBox(height: 32),

                // Título
                Text(
                  _isRegisto ? 'Criar Conta' : 'Iniciar Sessão',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtítulo
                Text(
                  _isRegisto
                      ? 'Descobre escolhas ilimitadas e conveniência incomparável'
                      : 'Bem-vindo de volta',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Campo Nome (só no modo registo, aparece em cima do Email)
                if (_isRegisto)
                  TextField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),

                if (_isRegisto) const SizedBox(height: 20),

                // Campo Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 20),

                // Campo Palavra-passe
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Palavra-passe',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 12),

                // Lembrar-me + Esqueci-me (flexível para evitar overflow)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Checkbox(
                            value: _lembrarMe,
                            onChanged: (value) => setState(() => _lembrarMe = value!),
                            activeColor: Colors.blue[700],
                          ),
                          const Flexible(
                            child: Text(
                              'Lembrar-me',
                              style: TextStyle(color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: TextButton(
                        onPressed: _recuperarPalavraPasse,
                        child: const Text(
                          'Esqueci-me da palavra-passe',
                          style: TextStyle(color: Colors.blue, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Botão principal
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : (_isRegisto ? _registarComEmail : _iniciarSessaoComEmail),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isRegisto ? 'CRIAR CONTA' : 'INICIAR SESSÃO',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Link para mudar modo
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRegisto = !_isRegisto;
                      _errorMessage = '';
                    });
                  },
                  child: Text(
                    _isRegisto
                        ? 'Já tens conta? Inicia sessão'
                        : 'Não tens conta? Regista-te',
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red[700], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 32),

                const Text(
                  '- OU -',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 24),

                // Botão Google
                GestureDetector(
                  onTap: _isLoading ? null : _iniciarSessaoComGoogle,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/products/google_logo.png',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continuar com Google',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}