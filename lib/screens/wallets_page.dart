import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/wallet.dart';
import 'transactions_page.dart';

class WalletsPage extends StatefulWidget {
  const WalletsPage({super.key});

  @override
  State<WalletsPage> createState() => _WalletsPageState();
}

class _WalletsPageState extends State<WalletsPage> {
  List<Wallet> _wallets = [];
  bool _isLoading = true;

  String _displayCurrency = 'USD';
  double _usdToFcfa = 600;
  double _eurToFcfa = 655;
  double _usdToEur = 0.92;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getWallets(),
        ApiService.getSettings(),
      ]);
      final settings = results[1] as Map<String, dynamic>;
      setState(() {
        _wallets = (results[0] as List).map((e) => Wallet.fromJson(e)).toList();
        _usdToFcfa = (settings['usdToFcfa'] ?? 600).toDouble();
        _eurToFcfa = (settings['eurToFcfa'] ?? 655).toDouble();
        _usdToEur = (settings['usdToEur'] ?? 0.92).toDouble();
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

  double _convert(double amount, String from) {
    if (from == _displayCurrency) return amount;
    if (from == 'EUR' && _displayCurrency == 'FCFA') return amount * _eurToFcfa;
    if (from == 'FCFA' && _displayCurrency == 'EUR') {
      return _eurToFcfa > 0 ? amount / _eurToFcfa : amount;
    }
    double inUsd;
    switch (from) {
      case 'USD':
        inUsd = amount;
        break;
      case 'EUR':
        inUsd = _usdToEur > 0 ? amount / _usdToEur : amount;
        break;
      case 'FCFA':
        inUsd = _usdToFcfa > 0 ? amount / _usdToFcfa : amount;
        break;
      default:
        inUsd = amount;
    }
    switch (_displayCurrency) {
      case 'EUR':
        return inUsd * _usdToEur;
      case 'FCFA':
        return inUsd * _usdToFcfa;
      default:
        return inUsd;
    }
  }

  void _showAddEditDialog([Wallet? wallet]) {
    final nameController = TextEditingController(text: wallet?.name ?? '');
    final balanceController = TextEditingController(
      text: wallet?.balance.toString() ?? '0',
    );
    String selectedCurrency = wallet?.currency ?? 'USD';
    String selectedType = wallet?.type ?? 'bank';
    String selectedColor = wallet?.color ?? '#3B82F6';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(wallet == null ? 'Add Wallet' : 'Edit Wallet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: balanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Balance',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(),
                  ),
                  items: Wallet.currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedCurrency = value!);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: Wallet.types
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedType = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'name': nameController.text,
                  'balance': double.tryParse(balanceController.text) ?? 0,
                  'currency': selectedCurrency,
                  'type': selectedType,
                  'color': selectedColor,
                };
                try {
                  if (wallet == null) {
                    await ApiService.createWallet(data);
                  } else {
                    await ApiService.updateWallet(wallet.id, data);
                  }
                  if (mounted) Navigator.pop(context);
                  _loadData();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              child: Text(wallet == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteWallet(Wallet wallet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wallet'),
        content: Text('Are you sure you want to delete "${wallet.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteWallet(wallet.id);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  IconData _getWalletIcon(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance;
      case 'cash':
        return Icons.money;
      case 'mobile':
        return Icons.phone_android;
      case 'wise':
        return Icons.language;
      case 'investment':
        return Icons.show_chart;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color _walletTypeColor(String type) {
    switch (type) {
      case 'bank':
        return const Color(0xFF3B82F6);
      case 'cash':
        return const Color(0xFF1A1A2E);
      case 'mobile':
        return const Color(0xFF8B5CF6);
      case 'wise':
        return const Color(0xFF06B6D4);
      case 'investment':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _formatNumber(double value) {
    final isNegative = value < 0;
    final abs = value.abs();
    final parts = abs.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(intPart[i]);
    }
    final result = buffer.toString();
    if (decPart == '00') {
      return '${isNegative ? '-' : ''}$result';
    }
    return '${isNegative ? '-' : ''}$result.$decPart';
  }

  @override
  Widget build(BuildContext context) {
    final visible = _wallets.where((w) => !w.isHidden).toList();
    final totalBalance = visible.fold<double>(
      0, (sum, w) => sum + _convert(w.balance, w.currency),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallets'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: ['USD', 'EUR', 'FCFA'].map((currency) {
                final isSelected = _displayCurrency == currency;
                return GestureDetector(
                  onTap: () => setState(() => _displayCurrency = currency),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepPurple : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currency,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.deepPurple,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _wallets.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text('No wallets found')),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Summary Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Balance',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_formatNumber(totalBalance)} $_displayCurrency',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildStat(
                                    '${visible.length}',
                                    'Wallets',
                                    Icons.account_balance_wallet_outlined,
                                  ),
                                  const SizedBox(width: 24),
                                  _buildStat(
                                    '${_wallets.where((w) => w.isHidden).length}',
                                    'Hidden',
                                    Icons.visibility_off_outlined,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Wallets Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: _wallets.length,
                          itemBuilder: (context, index) {
                            return _buildWalletCard(_wallets[index]);
                          },
                        ),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 16),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildWalletCard(Wallet wallet) {
    final color = _walletTypeColor(wallet.type);
    final convertedBalance = _convert(wallet.balance, wallet.currency);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TransactionsPage(wallet: wallet)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getWalletIcon(wallet.type),
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_horiz,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddEditDialog(wallet);
                      } else if (value == 'delete') {
                        _deleteWallet(wallet);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              wallet.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              wallet.type.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${_formatNumber(convertedBalance)} $_displayCurrency',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (wallet.currency != _displayCurrency)
              Text(
                '${_formatNumber(wallet.balance)} ${wallet.currency}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
