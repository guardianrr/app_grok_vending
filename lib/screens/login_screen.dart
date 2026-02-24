import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:app_grok_vending/utils/constants.dart';
import 'package:app_grok_vending/screens/login_instruction_screen.dart';  // <--- ADICIONADO ESTE IMPORT

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isRegister = false;

  Future<void> _authUser() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      if (_isRegister) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      print("Login/registo bem sucedido");

      if (!mounted) return;

      // Vai para a tela de instrução de ligação à máquina
      Navigator.pushReplacement(
        context,
          MaterialPageRoute(builder: (context) => const LoginInstructionScreen()),
);
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code} - ${e.message}");
      if (mounted) {
        setState(() {
          _errorMessage = switch (e.code) {
            'user-not-found' => 'Utilizador não encontrado.',
            'wrong-password' => 'Senha incorreta.',
            'weak-password' => 'A senha deve ter pelo menos 6 caracteres.',
            'email-already-in-use' => 'Este email já está registado.',
            'invalid-email' => 'Email inválido.',
            _ => 'Erro: ${e.message}',
          };
        });
      }
    } catch (e) {
      print("Erro inesperado: $e");
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro inesperado: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.blueGrey[900]!],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeInUp(
              duration: const Duration(milliseconds: 1200),
              child: GlassmorphicContainer(
                width: MediaQuery.of(context).size.width * 0.88,
                height: MediaQuery.of(context).size.height * 0.75,
                borderRadius: 32,
                blur: 20,
                alignment: Alignment.center,
                border: 2,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.cyan.withOpacity(0.6), Colors.blueAccent.withOpacity(0.6)],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        child: Text(
                          _isRegister ? 'Criar Conta' : 'Bem-vindo!',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 1000),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.cyan, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeInRight(
                        duration: const Duration(milliseconds: 1000),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Colors.cyan, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else
                        FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          child: ElevatedButton(
                            onPressed: _authUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan.withOpacity(0.9),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 10,
                              shadowColor: Colors.cyan.withOpacity(0.6),
                            ),
                            child: Text(
                              _isRegister ? 'Registar' : 'Entrar',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      FadeInUp(
                        duration: const Duration(milliseconds: 900),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isRegister = !_isRegister;
                              _errorMessage = '';
                            });
                          },
                          child: Text(
                            _isRegister ? 'Já tens conta? Entra aqui' : 'Não tens conta? Cria uma agora',
                            style: const TextStyle(color: Colors.cyan, fontSize: 16),
                          ),
                        ),
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text(
                            _errorMessage,
                            style: TextStyle(color: AppColors.error, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}