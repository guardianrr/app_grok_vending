import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' as foundation;

class MachineLoginScreen extends StatefulWidget {
  const MachineLoginScreen({super.key});

  @override
  State<MachineLoginScreen> createState() => _MachineLoginScreenState();
}

class _MachineLoginScreenState extends State<MachineLoginScreen> {
  final MobileScannerController cameraController = MobileScannerController();

  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    _isProcessing = true;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final customToken = barcode.rawValue!;
        foundation.debugPrint('QR Code lido (custom token): $customToken');
        await _exchangeAndSend(customToken);
        await cameraController.stop(); // Fecha a câmera para evitar tela preta
        Navigator.pop(context); // Volta à tela anterior
        break;
      }
    }

    _isProcessing = false;
  }

  Future<void> _exchangeAndSend(String customToken) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCustomToken(customToken);
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Falha ao trocar o token');
      }

      final idToken = await user.getIdToken();
      foundation.debugPrint('ID Token obtido: $idToken');

      final response = await http.post(
        Uri.parse('http://192.168.1.77:5000/verify_login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': idToken}),
      );

      foundation.debugPrint('Resposta do Pi: status ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (data['success']) {
        foundation.debugPrint('Login bem sucedido!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
      } else {
        foundation.debugPrint('Erro no Pi: ${data['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${data['message']}')),
        );
      }
    } catch (e) {
      foundation.debugPrint('Erro geral: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ler QR Code da Máquina'),
        centerTitle: true,
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: _onDetect,
      ),
    );
  }
}