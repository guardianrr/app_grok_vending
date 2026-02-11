import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:provider/provider.dart';
import 'package:app_grok_vending/utils/constants.dart';
import 'package:app_grok_vending/main.dart';

class PayNfcScreen extends StatefulWidget {
  const PayNfcScreen({super.key});

  @override
  State<PayNfcScreen> createState() => _PayNfcScreenState();
}

class _PayNfcScreenState extends State<PayNfcScreen> {
  bool _isPaying = false;
  String _statusMessage = '';
  final double _paymentAmount = 2.50; // Valor fictício do produto

  Future<void> _startNfcPayment() async {
    final appState = Provider.of<AppState>(context, listen: false);

    // Verificações básicas
    if (appState.cardId.isEmpty) {
      setState(() {
        _statusMessage = 'Primeiro adiciona o teu cartão NFC na aba "Cartão".';
      });
      return;
    }

    if (appState.balance < _paymentAmount) {
      setState(() {
        _statusMessage = 'Saldo insuficiente para pagar ${_paymentAmount.toStringAsFixed(2)} €.';
      });
      return;
    }

    setState(() {
      _isPaying = true;
      _statusMessage = 'Aproxime o telemóvel da máquina (PN532)...';
    });

    try {
      // Inicia sessão NFC – o PN532 deteta o telemóvel como tag
      await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 30),
      );

      // Dados que o PN532 vai poder ler (se configurado para detetar tag)
      String payload = '${appState.cardId}|${_paymentAmount.toStringAsFixed(2)}';

      // Debita o saldo na app (simulação de sucesso – o PN532 detetou)
      appState.subtractBalance(_paymentAmount);

      setState(() {
        _statusMessage = 'Pagamento enviado com sucesso!\n' 'Débitado: ${_paymentAmount.toStringAsFixed(2)} €\n' +
            'Saldo atual: ${appState.balance.toStringAsFixed(2)} €\n' +
            'Dados enviados (para o PN532): $payload';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao aproximar: $e\nTenta de novo ou verifica o NFC ativado.';
      });
    } finally {
      await FlutterNfcKit.finish(); // Sempre fecha a sessão
      setState(() {
        _isPaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final bool canPay = appState.cardId.isNotEmpty && appState.balance >= _paymentAmount;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.nfc_rounded,
                size: 120,
                color: canPay ? AppColors.success : AppColors.primary,
              ),
              const SizedBox(height: 40),

              const Text(
                'Pagamento Contactless',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              if (appState.cardId.isNotEmpty)
                Text(
                  'Cartão: ${appState.cardId}',
                  style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
              const SizedBox(height: 8),

              Text(
                'Saldo: ${appState.balance.toStringAsFixed(2)} €',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: canPay ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                'Valor do produto: ${_paymentAmount.toStringAsFixed(2)} €',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 40),

              ElevatedButton.icon(
                onPressed: _isPaying || !canPay ? null : _startNfcPayment,
                icon: const Icon(Icons.touch_app, size: 32),
                label: Text(
                  _isPaying ? 'A pagar...' : 'Pagar NFC',
                  style: const TextStyle(fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
              ),

              const SizedBox(height: 40),

              if (_statusMessage.isNotEmpty)
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: _statusMessage.contains('sucesso') ? AppColors.success : AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}