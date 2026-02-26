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

      // Aqui envias os dados para a máquina/DB (ajusta com o teu fluxo real)
      // Exemplo simples (podes usar Firebase para notificar a máquina):
      // final user = FirebaseAuth.instance.currentUser;
      // if (user != null) {
      //   await FirebaseDatabase.instance.ref('pagamentos/${user.uid}').push().set({
      //     'valor': totalDoCarrinho, // tens de ter isso no AppState
      //     'itens': carrinho.map((item) => item.nome).toList(),
      //     'timestamp': DateTime.now().toIso8601String(),
      //     'nfcTagData': tag.toString(),
      //   });
      // }

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

      // Volta automaticamente para a tela de saldo/produtos após 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pop(context); // Volta para HomeScreen (saldo/produtos)
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
      appBar: AppBar(
        title: const Text('Pagamento NFC'),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.blueGrey[900]!],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone NFC grande e estático (sem animação de expansão)
              const Icon(
                Icons.nfc,
                size: 180,
                color: Colors.cyan,
              ),
              const SizedBox(height: 40),

              // Título principal (centrado e formatado)
              const Text(
                'Pagamento NFC Contactless',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Instrução clara e bem centrada
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  _isScanning
                      ? _statusMessage
                      : 'Encoste o telemóvel ao leitor NFC da máquina para pagar',
                  style: TextStyle(
                    fontSize: 20,
                    color: _isScanning ? Colors.cyan : Colors.white70,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),

              // Botão único: Iniciar Pagamento NFC
              if (!_isScanning)
                ElevatedButton.icon(
                  onPressed: _startNfcPayment,
                  icon: const Icon(Icons.nfc, size: 28),
                  label: const Text(
                    'Pagar com NFC',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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