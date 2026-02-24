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

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getWallets();
      setState(() {
        _wallets = data.map((e) => Wallet.fromJson(e)).toList();
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
                  _loadWallets();
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
        _loadWallets();
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
        return Icons.swap_horiz;
      case 'investment':
        return Icons.trending_up;
      default:
        return Icons.wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallets'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWallets,
              child: _wallets.isEmpty
                  ? const Center(child: Text('No wallets found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _wallets.length,
                      itemBuilder: (context, index) {
                        final wallet = _wallets[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child: Icon(
                                _getWalletIcon(wallet.type),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(wallet.name),
                            subtitle: Text(wallet.type.toUpperCase()),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${wallet.balance.toStringAsFixed(2)} ${wallet.currency}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showAddEditDialog(wallet);
                                    } else if (value == 'delete') {
                                      _deleteWallet(wallet);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TransactionsPage(wallet: wallet),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
