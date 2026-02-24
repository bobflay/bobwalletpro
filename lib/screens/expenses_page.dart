import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/expense.dart';
import '../models/wallet.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  List<Expense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getExpenses();
      setState(() {
        _expenses = data.map((e) => Expense.fromJson(e)).toList();
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'housing':
        return Icons.home;
      case 'family':
        return Icons.family_restroom;
      case 'utilities':
        return Icons.bolt;
      case 'transport':
        return Icons.directions_car;
      case 'healthcare':
        return Icons.local_hospital;
      case 'food':
        return Icons.restaurant;
      case 'financial':
        return Icons.account_balance;
      default:
        return Icons.category;
    }
  }

  void _showAddEditDialog([Expense? expense]) {
    final nameController = TextEditingController(text: expense?.name ?? '');
    final amountController = TextEditingController(
      text: expense?.amount.toString() ?? '',
    );
    final notesController = TextEditingController(text: expense?.notes ?? '');
    String selectedCurrency = expense?.currency ?? 'USD';
    String selectedFrequency = expense?.frequency ?? 'monthly';
    String selectedCategory = expense?.category ?? 'other';
    bool isRecurring = expense?.isRecurring ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(expense == null ? 'Add Expense' : 'Edit Expense'),
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
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: Expense.categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedCategory = value!);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                  items: Expense.frequencies
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
                SwitchListTile(
                  title: const Text('Recurring'),
                  value: isRecurring,
                  onChanged: (value) {
                    setDialogState(() => isRecurring = value);
                  },
                ),
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
                  'category': selectedCategory,
                  'is_recurring': isRecurring,
                  'notes': notesController.text,
                };
                try {
                  if (expense == null) {
                    await ApiService.createExpense(data);
                  } else {
                    await ApiService.updateExpense(expense.id, data);
                  }
                  if (mounted) Navigator.pop(context);
                  _loadExpenses();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              child: Text(expense == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.name}"?'),
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
        await ApiService.deleteExpense(expense.id);
        _loadExpenses();
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
        title: const Text('Expenses'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExpenses,
              child: _expenses.isEmpty
                  ? const Center(child: Text('No expenses found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _expenses.length,
                      itemBuilder: (context, index) {
                        final expense = _expenses[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.red,
                              child: Icon(
                                _getCategoryIcon(expense.category),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(expense.name),
                            subtitle: Text(
                              '${expense.category.toUpperCase()} - ${expense.frequency.toUpperCase()}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${expense.amount.toStringAsFixed(2)} ${expense.currency}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showAddEditDialog(expense);
                                    } else if (value == 'delete') {
                                      _deleteExpense(expense);
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
