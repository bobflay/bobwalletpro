class Transaction {
  final int id;
  final int walletId;
  final String type;
  final double amount;
  final String currency;
  final String? notes;
  final DateTime transactionDate;

  Transaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.currency,
    this.notes,
    required this.transactionDate,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      walletId: json['wallet_id'],
      type: json['type'],
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'],
      notes: json['notes'],
      transactionDate: DateTime.parse(json['transaction_date']),
    );
  }

  static const List<String> types = ['credit', 'debit'];
}
