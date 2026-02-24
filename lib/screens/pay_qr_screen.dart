import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PayQrScreen extends StatefulWidget {
  const PayQrScreen({super.key});

  @override
  State<PayQrScreen> createState() => _PayQrScreenState();
}

class _PayQrScreenState extends State<PayQrScreen> {
  final MobileScannerController cameraController = MobileScannerController();

  bool _showCamera = false;
  bool _qrLido = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _processQrCode(String code) async {
    if (_qrLido) return;

    _qrLido = true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('QR lido: $code'), backgroundColor: Colors.blue),
    );

    try {
      final uri = Uri.parse(code);

      if (uri.scheme != 'vending' || uri.host != 'pagar') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR inválido'), backgroundColor: Colors.red),
        );
        return;
      }

      final maquina = uri.queryParameters['maquina'];
      final pedidoId = uri.queryParameters['pedidoId'];
      final totalStr = uri.queryParameters['total'];

      if (maquina == null || pedidoId == null || totalStr == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR incompleto'), backgroundColor: Colors.red),
        );
        return;
      }

      final totalFixed = totalStr.replaceAll(',', '.');
      final double total = double.tryParse(totalFixed) ?? 0.0;

      if (total <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Valor inválido'), backgroundColor: Colors.red),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não estás logado'), backgroundColor: Colors.red),
        );
        return;
      }

      final dbRef = FirebaseDatabase.instance.ref();

      // Verifica se já foi pago
      final pagamento = await dbRef.child('pagamentos/$maquina/$pedidoId').get();
      if (pagamento.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este QR já foi pago!'), backgroundColor: Colors.orange),
        );
        return;
      }

      // Lê saldo
      final saldoSnap = await dbRef.child('users/${user.uid}/saldo').get();
      final double saldoAtual = (saldoSnap.value as num?)?.toDouble() ?? 0.0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saldo atual: $saldoAtual €'), backgroundColor: Colors.blueGrey),
      );

      if (saldoAtual < total) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saldo insuficiente: $saldoAtual €'), backgroundColor: Colors.red),
        );
        return;
      }

      // Deduz saldo
      await dbRef.child('users/${user.uid}/saldo').set(saldoAtual - total);

      // Regista pagamento
      await dbRef.child('pagamentos/$maquina/$pedidoId').set({
        'confirmado': true,
        'userId': user.uid,
        'total': total,
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pagamento de $total € OK! Novo saldo: ${saldoAtual - total} €'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );

      // Fecha scanner
      cameraController.stop();
      setState(() => _showCamera = false);

    } catch (e) {
      print('ERRO: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _openCamera() {
    _qrLido = false;
    setState(() => _showCamera = true);
    cameraController.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagar com QR Code'), centerTitle: true),
      body: _showCamera
          ? Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final raw = barcode.rawValue;
                      if (raw != null && raw.isNotEmpty) {
                        _processQrCode(raw);
                        break;
                      }
                    }
                  },
                ),
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        color: Colors.white,
                        iconSize: 40,
                        icon: const Icon(Icons.flash_on),
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
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 40),
                    onPressed: () {
                      cameraController.stop();
                      setState(() => _showCamera = false);
                    },
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, size: 120, color: Colors.cyan),
                  const SizedBox(height: 40),
                  const Text('Pagar com QR Code', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _openCamera,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Abrir Scanner'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}