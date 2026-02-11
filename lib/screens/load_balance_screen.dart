import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_grok_vending/utils/constants.dart';
import 'package:app_grok_vending/main.dart';

class LoadBalanceScreen extends StatefulWidget {
  const LoadBalanceScreen({super.key});

  @override
  State<LoadBalanceScreen> createState() => _LoadBalanceScreenState();
}

class _LoadBalanceScreenState extends State<LoadBalanceScreen> {
  final TextEditingController _customController = TextEditingController();
  double _selectedAmount = 0.0;
  String _statusMessage = '';

  final List<double> presetAmounts = [5.0, 10.0, 20.0, 50.0, 100.0];

  void _selectPreset(double amount) {
    setState(() {
      _selectedAmount = amount;
      _customController.clear();
    });
  }

  void _loadBalance() {
    final appState = Provider.of<AppState>(context, listen: false);

    double amount;

    if (_selectedAmount > 0) {
      amount = _selectedAmount;
    } else {
      final text = _customController.text.replaceAll(',', '.');
      amount = double.tryParse(text) ?? 0.0;
    }

    if (amount <= 0) {
      setState(() {
        _statusMessage = 'Insira um valor válido maior que 0.';
      });
      return;
    }

    appState.addBalance(amount);

    setState(() {
      _statusMessage = 'Carregado com sucesso +${amount.toStringAsFixed(2)} €!\nSaldo atual: ${appState.balance.toStringAsFixed(2)} €';
      _selectedAmount = 0.0;
      _customController.clear();
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _statusMessage = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carregar Saldo'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Saldo atual - card simples e compacto
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                'Saldo Atual',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${appState.balance.toStringAsFixed(2)} €',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Valores rápidos - botões menores e em grid 3x2
                      const Text(
                        'Valores rápidos',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.6,
                        ),
                        itemCount: presetAmounts.length,
                        itemBuilder: (context, index) {
                          final amount = presetAmounts[index];
                          final isSelected = _selectedAmount == amount && _customController.text.isEmpty;
                          return ElevatedButton(
                            onPressed: () => _selectPreset(amount),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected ? AppColors.primary : Colors.white,
                              foregroundColor: isSelected ? Colors.white : AppColors.primary,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: isSelected ? 6 : 2,
                            ),
                            child: Text(
                              '${amount.toStringAsFixed(0)} €',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Campo personalizado - compacto
                      const Text(
                        'Valor personalizado',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Valor (€)',
                          prefixText: '€ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedAmount = 0.0;
                          });
                        },
                      ),

                      const SizedBox(height: 32),

                      // Botão principal - grande e destacado
                      ElevatedButton.icon(
                        onPressed: _loadBalance,
                        icon: const Icon(Icons.payment, size: 28),
                        label: const Text('Carregar Saldo', style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Mensagem de feedback - no fundo, com espaço
                      if (_statusMessage.isNotEmpty)
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 16,
                            color: _statusMessage.contains('sucesso') ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}