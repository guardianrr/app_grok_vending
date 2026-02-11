import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:app_grok_vending/utils/constants.dart';
import 'package:app_grok_vending/main.dart';

class PayQrScreen extends StatefulWidget {
  const PayQrScreen({super.key});

  @override
  State<PayQrScreen> createState() => _PayQrScreenState();
}

class _PayQrScreenState extends State<PayQrScreen> {
  final MobileScannerController cameraController = MobileScannerController();

  bool _isProcessing = false;
  bool _showCamera = false; // Controla se a câmera aparece ou não

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _processQrCode(String code) async {
    if (_isProcessing) return;
    _isProcessing = true;

    final double? amount = double.tryParse(code.trim());

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR Code inválido ou valor não reconhecido.')),
      );
      _isProcessing = false;
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);

    if (appState.balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saldo insuficiente para pagar $amount €.')),
      );
      _isProcessing = false;
      return;
    }

    appState.subtractBalance(amount);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pagamento de $amount € efetuado com sucesso!'),
        backgroundColor: AppColors.success,
      ),
    );

    cameraController.stop();
    _isProcessing = false;
  }

  void _openCamera() {
    setState(() {
      _showCamera = true;
    });
    cameraController.start();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (_showCamera) {
      // Modo câmera fullscreen (sem texto, só câmera + botões no fundo)
      return Scaffold(
        body: Stack(
          children: [
            MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _processQrCode(barcode.rawValue!);
                    break;
                  }
                }
              },
            ),
            // Botões de controlo no fundo da câmera
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    color: Colors.white,
                    iconSize: 40,
                    icon: const Icon(Icons.flash_off), // Pode ser atualizado se quiseres
                    onPressed: () => cameraController.toggleTorch(),
                  ),
                  IconButton(
                    color: Colors.white,
                    iconSize: 40,
                    icon: const Icon(Icons.cameraswitch),
                    onPressed: () => cameraController.switchCamera(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Modo inicial: texto + botão (sem câmera aberta)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagar com QR Code'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner_rounded, size: 100, color: AppColors.primary),
              const SizedBox(height: 40),
              const Text(
                'Pagamento por QR Code',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Saldo atual: ${appState.balance.toStringAsFixed(2)} €',
                style: const TextStyle(fontSize: 22, color: AppColors.success, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              const Text(
                'Aponte a câmera para o QR Code na máquina de vendas.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _openCamera,
                icon: const Icon(Icons.qr_code_scanner, size: 32),
                label: const Text('Pagar com QR Code', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}