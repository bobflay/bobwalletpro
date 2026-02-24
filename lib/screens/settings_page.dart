import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _usdToFcfaController = TextEditingController();
  final _eurToFcfaController = TextEditingController();
  final _usdToEurController = TextEditingController();
  final _goldPriceController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _usdToFcfaController.dispose();
    _eurToFcfaController.dispose();
    _usdToEurController.dispose();
    _goldPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getSettings();
      setState(() {
        _usdToFcfaController.text = (data['usdToFcfa'] ?? 600).toString();
        _eurToFcfaController.text = (data['eurToFcfa'] ?? 655).toString();
        _usdToEurController.text = (data['usdToEur'] ?? 0.92).toString();
        _goldPriceController.text = (data['goldPricePerOunce'] ?? 2000).toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await ApiService.updateSettings({
        'usdToFcfa': double.tryParse(_usdToFcfaController.text) ?? 600,
        'eurToFcfa': double.tryParse(_eurToFcfaController.text) ?? 655,
        'usdToEur': double.tryParse(_usdToEurController.text) ?? 0.92,
        'goldPricePerOunce': double.tryParse(_goldPriceController.text) ?? 2000,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Exchange Rates',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usdToFcfaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'USD to FCFA',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _eurToFcfaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'EUR to FCFA',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.euro),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usdToEurController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'USD to EUR',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_exchange),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Commodity Prices',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _goldPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Gold Price per Ounce (USD)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.diamond),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
