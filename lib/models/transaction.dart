class Transaction {
  final int id;
  final int walletId;
  final String type;
  final double amount;
  final String currency;
  final String? notes;
  final DateTime transactionDate;
  final DateTime? createdAt;

  Transaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.currency,
    this.notes,
    required this.transactionDate,
    this.createdAt,
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
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  static const List<String> types = ['credit', 'debit'];
}
