import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class LoginInstructionScreen extends StatefulWidget {
  const LoginInstructionScreen({super.key});

  @override
  State<LoginInstructionScreen> createState() => _LoginInstructionScreenState();
}

class _LoginInstructionScreenState extends State<LoginInstructionScreen> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool scanning = false;   // Começa desligado
  bool loading = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _processQrCode(Barcode barcode) {
    final String? code = barcode.rawValue;
    if (code == null || !code.startsWith('vending://login')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("QR não reconhecido! Tenta novamente."),
          backgroundColor: Colors.red,
        ),
      );
      return; // Continua a scanear
    }

    setState(() {
      scanning = false;
      loading = true;
    });
    cameraController.stop();

    final uri = Uri.parse(code);
    final loginId = uri.queryParameters['loginId'];

    if (loginId == null) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("QR inválido! Tenta escanear novamente."),
          backgroundColor: Colors.red,
        ),
      );
      _resumeScanning();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Utilizador não autenticado!"),
          backgroundColor: Colors.red,
        ),
      );
      _resumeScanning();
      return;
    }

    FirebaseDatabase.instance.ref('login_requests/$loginId').set({
      'uid': user.uid,
      'timestamp': DateTime.now().toIso8601String(),
    }).then((_) {
      // Pop-up de sucesso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text("Leitura Concluída!", style: TextStyle(color: Colors.green)),
            content: const Text(
              "Login realizado com sucesso na máquina.\n\nContinuar na máquina agora?",
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  setState(() {
                    loading = false;
                    scanning = true;
                  });
                  cameraController.start();
                },
                child: const Text("Cancelar", style: TextStyle(color: Colors.red, fontSize: 18)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: const Text("Continuar na Máquina", style: TextStyle(color: Colors.green, fontSize: 18)),
              ),
            ],
          );
        },
      );
    }).catchError((error) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao ligar conta: $error"),
          backgroundColor: Colors.red,
        ),
      );
      _resumeScanning();
    });
  }

  void _resumeScanning() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          scanning = true;
          loading = false;
        });
        cameraController.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ligar à Máquina de Vendas"),
        backgroundColor: Colors.cyan,
      ),
      body: Stack(
        children: [
          // Scanner (só aparece quando clica no botão)
          if (scanning)
            MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  _processQrCode(barcode);
                }
              },
              // Overlay de orientação (quadrado verde no centro)
              overlayBuilder: (context, constraints) {
                final double scanWindowSize = 300.0; // tamanho do quadrado
                return Center(
                  child: Container(
                    width: scanWindowSize,
                    height: scanWindowSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              },
            ),

          // Conteúdo principal (texto + botão) - só aparece quando NÃO está a scanear
          if (!scanning && !loading)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 140,
                    color: Colors.cyan,
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "Para comprar na máquina de vendas,\n"
                    "escaneie o QR Code que aparece na tela da máquina.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Botão grande e centralizado
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        scanning = true;
                        loading = false;
                      });
                      cameraController.start();
                    },
                    icon: const Icon(Icons.camera_alt, size: 32),
                    label: const Text(
                      "Escanear QR da Máquina",
                      style: TextStyle(fontSize: 22),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(double.infinity, 70),
                    ),
                  ),
                ],
              ),
            ),

          // Loading overlay quando processa o QR
          if (loading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 6),
              ),
            ),
        ],
      ),
    );
  }
}