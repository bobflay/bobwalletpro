import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/income.dart';
import '../models/wallet.dart';

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  List<Income> _incomes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncomes();
  }

  Future<void> _loadIncomes() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getIncome();
      setState(() {
        _incomes = data.map((e) => Income.fromJson(e)).toList();
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

  void _showAddEditDialog([Income? income]) {
    final nameController = TextEditingController(text: income?.name ?? '');
    final amountController = TextEditingController(
      text: income?.amount.toString() ?? '',
    );
    final notesController = TextEditingController(text: income?.notes ?? '');
    String selectedCurrency = income?.currency ?? 'USD';
    String selectedFrequency = income?.frequency ?? 'monthly';
    String selectedType = income?.type ?? 'fixed';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(income == null ? 'Add Income' : 'Edit Income'),
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
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
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
                  value: selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                  items: Income.frequencies
                      .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(f.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedFrequency = value!);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: Income.types
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedType = value!);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                  'amount': double.tryParse(amountController.text) ?? 0,
                  'currency': selectedCurrency,
                  'frequency': selectedFrequency,
                  'type': selectedType,
                  'notes': notesController.text,
                };
                try {
                  if (income == null) {
                    await ApiService.createIncome(data);
                  } else {
                    await ApiService.updateIncome(income.id, data);
                  }
                  if (mounted) Navigator.pop(context);
                  _loadIncomes();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              child: Text(income == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteIncome(Income income) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income'),
        content: Text('Are you sure you want to delete "${income.name}"?'),
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
        await ApiService.deleteIncome(income.id);
        _loadIncomes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadIncomes,
              child: _incomes.isEmpty
                  ? const Center(child: Text('No income found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _incomes.length,
                      itemBuilder: (context, index) {
                        final income = _incomes[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Icon(
                                income.type == 'fixed'
                                    ? Icons.attach_money
                                    : Icons.trending_up,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(income.name),
                            subtitle: Text(
                              '${income.frequency.toUpperCase()} - ${income.type.toUpperCase()}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${income.amount.toStringAsFixed(2)} ${income.currency}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showAddEditDialog(income);
                                    } else if (value == 'delete') {
                                      _deleteIncome(income);
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
