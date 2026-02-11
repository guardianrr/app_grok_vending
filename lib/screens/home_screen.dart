import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_grok_vending/models/product_model.dart';
import 'package:app_grok_vending/utils/constants.dart';
import 'package:app_grok_vending/main.dart';
import 'package:app_grok_vending/screens/payment_confirmation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Product> products = [
    Product(
      name: 'Garrafa de Água 50cl',
      price: 0.80,
      imageUrl: 'assets/images/products/agua_50cl.png',
    ),
    Product(
      name: 'KitKat',
      price: 1.20,
      imageUrl: 'assets/images/products/kitkat.png',
    ),
    Product(
      name: 'Sandes Mista',
      price: 2.50,
      imageUrl: 'assets/images/products/sandes_mista.png',
    ),
    Product(
      name: 'Ice Tea 33cl',
      price: 1.50,
      imageUrl: 'assets/images/products/ice_tea.png',
    ),
  ];

  Future<void> _showLogoutDialog() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Terminar Sessão'),
          content: const Text('Tem a certeza que quer terminar a sua sessão?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Não
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Sim
              child: const Text('Sim', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut(); // Termina a sessão
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos Disponíveis'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Terminar Sessão',
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Saldo atual no topo
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppColors.primary.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Saldo Atual:', style: TextStyle(fontSize: 18)),
                Text(
                  '${appState.balance.toStringAsFixed(2)} €',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.success),
                ),
              ],
            ),
          ),

          // Grid de produtos
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 5,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.asset(
                            product.imageUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            alignment: Alignment.center,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.broken_image, color: Colors.red, size: 50),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${product.price.toStringAsFixed(2)} €',
                              style: const TextStyle(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () {
                                  appState.selectProduct(product);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const PaymentConfirmationScreen()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text('Comprar', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}