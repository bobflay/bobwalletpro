class Expense {
  final int id;
  final String name;
  final double amount;
  final String currency;
  final String frequency;
  final String category;
  final bool isRecurring;
  final String? notes;

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.frequency,
    required this.category,
    required this.isRecurring,
    this.notes,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      name: json['name'],
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'],
      frequency: json['frequency'],
      category: json['category'],
      isRecurring: json['is_recurring'] ?? false,
      notes: json['notes'],
    );
  }

  static const List<String> categories = [
    'housing',
    'family',
    'utilities',
    'transport',
    'healthcare',
    'food',
    'financial',
    'other'
  ];
  static const List<String> frequencies = [
    'monthly',
    'bimonthly',
    'quarterly',
    'weekly',
    'biweekly',
    'semiannual',
    'annual',
    'one-time'
  ];
}
