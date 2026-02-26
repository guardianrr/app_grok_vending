import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:app_grok_vending/models/product_model.dart';
import 'package:app_grok_vending/main.dart'; // isto importa o AppState do main.dart

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos na Máquina'),
        centerTitle: true,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return Column(
            children: [
              // Box fixa em cima: Olá + Saldo
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[800]!, Colors.cyan[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá, ${appState.name}!',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bem-vindo de volta',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${appState.balance.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Espaço para não colar nos cards
              const SizedBox(height: 8),

              // Listagem de produtos
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance.ref('products').onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Erro: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                      return const Center(child: Text('Sem produtos disponíveis'));
                    }

                    final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                    final List<Product> products = data.entries.map((entry) {
                      final key = entry.key as String;
                      final value = entry.value as Map<dynamic, dynamic>;
                      return Product.fromMap(key, value);
                    }).toList();

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductInfoCard(product: product);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Card informativo simples (sem ações de compra)
class ProductInfoCard extends StatelessWidget {
  final Product product;

  const ProductInfoCard({super.key, required this.product});

  String _getImagePath(String productId) {
    final id = productId.toLowerCase();

    if (id.contains('coca') || id.contains('cola')) {
      return 'assets/images/products/sandes_mista.png';
    } else if (id.contains('chocolate') || id.contains('kitkat')) {
      return 'assets/images/products/kitkat.png';
    } else if (id.contains('agua') || id.contains('água')) {
      return 'assets/images/products/agua_50cl.png';
    } else if (id.contains('ice') || id.contains('tea') || id.contains('ice-tea')) {
      return 'assets/images/products/ice_tea.png';
    } else {
      print('Produto sem imagem mapeada: $productId');
      return 'assets/images/placeholder.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool temStock = product.stock > 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagem
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                _getImagePath(product.id),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('ERRO IMAGEM - Produto: ${product.id} | Caminho: ${_getImagePath(product.id)} | Erro: $error');
                  return const Center(
                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  );
                },
              ),
            ),
          ),

          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                Text(
                  '${product.price.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 6),

                Row(
                  children: [
                    Icon(
                      temStock ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: temStock ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stock: ${product.stock}',
                      style: TextStyle(
                        fontSize: 14,
                        color: temStock ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: temStock ? Colors.blue[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    temStock
                        ? 'Disponível apenas na máquina de vending'
                        : 'Produto esgotado no momento',
                    style: TextStyle(
                      fontSize: 11,
                      color: temStock ? Colors.blue[900] : Colors.red[900],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}