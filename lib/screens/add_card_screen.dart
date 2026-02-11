import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:provider/provider.dart';
import 'package:app_grok_vending/utils/constants.dart';
import 'package:app_grok_vending/main.dart'; // Para AppState

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  String _statusMessage = '';
  bool _isReading = false;

  Future<void> _lerCartao() async {
    setState(() {
      _isReading = true;
      _statusMessage = 'Aproxime o cartão NFC do telemóvel...';
    });

    try {
      NFCTag tag = await FlutterNfcKit.poll(timeout: const Duration(seconds: 20));

      String cardId = tag.id;

      // Guarda no estado global
      Provider.of<AppState>(context, listen: false).setCardId(cardId);

      setState(() {
        _statusMessage = 'Cartão adicionado com sucesso!\nID: $cardId';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao ler cartão: $e';
      });
    } finally {
      await FlutterNfcKit.finish();
      setState(() {
        _isReading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final bool hasCard = appState.cardId.isNotEmpty;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.credit_card_rounded,
                size: 100,
                color: hasCard ? AppColors.success : AppColors.primary,
              ),
              const SizedBox(height: 40),
              Text(
                hasCard ? 'Cartão NFC Adicionado' : 'Adicionar Cartão NFC',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (hasCard)
                Column(
                  children: [
                    const Text('ID do Cartão:', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    SelectableText(appState.cardId, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 30),
                  ],
                ),
              if (!hasCard)
                ElevatedButton.icon(
                  onPressed: _isReading ? null : _lerCartao,
                  icon: const Icon(Icons.nfc),
                  label: Text(_isReading ? 'A ler...' : 'Ler Cartão NFC'),
                ),
              const SizedBox(height: 30),
              if (_statusMessage.isNotEmpty)
                Text(
                  _statusMessage,
                  style: TextStyle(fontSize: 16, color: _statusMessage.contains('sucesso') ? AppColors.success : AppColors.error),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}