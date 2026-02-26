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
      _statusMessage = 'Aproxime o cartão da escola ao telemóvel...';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Título grande e centrado
                Text(
                  hasCard ? 'Cartão Já Adicionado' : 'Adicionar Cartão NFC',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtítulo explicativo
                Text(
                  hasCard
                      ? 'O teu cartão da escola já está ligado à app!'
                      : 'Vamos ligar o teu cartão da escola à app TAP&GO',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Ícone grande e giro (cartão NFC) – bem centrado
                Icon(
                  Icons.credit_card_rounded,
                  size: 120,
                  color: hasCard ? AppColors.success : AppColors.primary,
                ),
                const SizedBox(height: 40),

                // Instruções passo a passo (intuitivo e claro, bem centrado)
                if (!hasCard) ...[
                  const Text(
                    '1. Aproxime o cartão da escola ao telemóvel',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '2. Aguarde o sinal de leitura',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '3. Pronto! O teu cartão está ligado',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],

                // Botão principal grande e azul (bem centrado)
                if (!hasCard)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isReading ? null : _lerCartao,
                      icon: const Icon(Icons.nfc, size: 28),
                      label: Text(
                        _isReading ? 'A ler...' : 'Ler Cartão NFC Agora',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                    ),
                  ),

                if (hasCard)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'ID do Cartão:',
                        style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        appState.cardId,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _isReading ? null : _lerCartao,
                          icon: const Icon(Icons.nfc, size: 28),
                          label: Text(
                            _isReading ? 'A ler...' : 'Ler Novo Cartão',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.blue[700]!, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),

                // Mensagem de status (sucesso/erro, bem centrado)
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
      ),
    );
  }
}