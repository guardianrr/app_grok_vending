import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class PayNfcScreen extends StatefulWidget {
  const PayNfcScreen({super.key});

  @override
  State<PayNfcScreen> createState() => _PayNfcScreenState();
}

class _PayNfcScreenState extends State<PayNfcScreen> {
  bool _isScanning = false;
  String _statusMessage = 'Pronto para pagar';

  Future<void> _startNfcPayment() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'A aguardar contacto com o leitor NFC da máquina...';
    });

    try {
      // Verifica se o dispositivo suporta NFC
      bool isAvailable = await FlutterNfcKit.nfcAvailability == NFCAvailability.available;
      if (!isAvailable) {
        setState(() {
          _isScanning = false;
          _statusMessage = 'NFC não disponível neste dispositivo';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NFC não suportado ou desativado no teu telemóvel')),
        );
        return;
      }

      // Inicia leitura NFC
      var tag = await FlutterNfcKit.poll(
        timeout: Duration(seconds: 30),
        iosMultipleTagMessage: "Múltiplas tags detetadas, aproxime apenas uma",
        iosAlertMessage: "Aproxime o telemóvel ao leitor NFC",
      );

      // Tag lido com sucesso
      setState(() {
        _statusMessage = 'Leitura NFC detetada! Pagamento enviado...';
      });

      // Aqui podes processar o que a tag devolve (deixa comentado por agora)
      // String valorRecebido = tag.id ?? tag.toString(); // exemplo simples
      // print('Conteúdo da tag: $valorRecebido');

      // Mostra sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento NFC realizado com sucesso!')),
      );

      // Para a sessão NFC
      await FlutterNfcKit.finish();

      setState(() {
        _isScanning = false;
        _statusMessage = 'Pagamento concluído!';
      });

      // Volta automaticamente para HomeScreen após 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pop(context);
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Erro na leitura NFC';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro NFC: $e')),
      );
      await FlutterNfcKit.finish();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'Pagamento NFC',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtítulo explicativo
                const Text(
                  'Paga de forma rápida e segura na máquina TAP&GO',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Ícone NFC grande e centrado
                Icon(
                  Icons.nfc,
                  size: 120,
                  color: _isScanning ? Colors.blue[700] : Colors.grey[800],
                ),
                const SizedBox(height: 40),

                // Instrução clara e bem centrada
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    _isScanning
                        ? _statusMessage
                        : 'Encoste o telemóvel ao leitor NFC da máquina para pagar',
                    style: TextStyle(
                      fontSize: 18,
                      color: _isScanning ? Colors.blue[700] : Colors.black87,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),

                // Botão grande e azul (igual ao da tua login)
                if (!_isScanning)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _startNfcPayment,
                      icon: const Icon(Icons.nfc, size: 28),
                      label: const Text(
                        'Pagar com NFC',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                    ),
                  ),

                // Mensagem de status (bem centrado)
                if (_statusMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 16,
                        color: _statusMessage.contains('concluído') || _statusMessage.contains('sucesso')
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                      textAlign: TextAlign.center,
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