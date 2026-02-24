class Income {
  final int id;
  final String name;
  final double amount;
  final String currency;
  final String frequency;
  final String type;
  final String? notes;

  Income({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.frequency,
    required this.type,
    this.notes,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'],
      name: json['name'],
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'],
      frequency: json['frequency'],
      type: json['type'],
      notes: json['notes'],
    );
  }

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
  static const List<String> types = ['fixed', 'potential'];
}
