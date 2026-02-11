import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_grok_vending/models/product_model.dart';
import 'package:app_grok_vending/utils/constants.dart';
import 'package:app_grok_vending/main.dart';
import 'package:app_grok_vending/screens/pay_qr_screen.dart';
import 'package:app_grok_vending/screens/pay_nfc_screen.dart';

class PaymentConfirmationScreen extends StatelessWidget {
  const PaymentConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final product = appState.selectedProduct;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: const Center(child: Text('Nenhum produto escolhido')),
      );
    }

    final bool canPay = appState.balance >= product.price;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmação de Pagamento', overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagem do produto escolhido (em assets, centralizada)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  product.imageUrl,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, color: Colors.red, size: 80);
                  },
                ),
              ),
              const SizedBox(height: 24),

              Text(
                product.name,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${product.price.toStringAsFixed(2)} €',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              Text(
                'Saldo atual: ${appState.balance.toStringAsFixed(2)} €',
                style: TextStyle(fontSize: 20, color: canPay ? AppColors.success : AppColors.error),
              ),
              const SizedBox(height: 40),
              if (canPay)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PayQrScreen()),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner, size: 24),
                      label: const Text('Pagar com QR', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PayNfcScreen()),
                        );
                      },
                      icon: const Icon(Icons.nfc, size: 24),
                      label: const Text('Pagar com NFC', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  'Saldo insuficiente. Carrega mais saldo!',
                  style: TextStyle(fontSize: 18, color: AppColors.accent),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}