class Wallet {
  final int id;
  final String name;
  final String currency;
  final double balance;
  final String type;
  final String? color;
  final bool isHidden;

  Wallet({
    required this.id,
    required this.name,
    required this.currency,
    required this.balance,
    required this.type,
    this.color,
    this.isHidden = false,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      name: json['name'],
      currency: json['currency'],
      balance: (json['balance'] ?? 0).toDouble(),
      type: json['type'],
      color: json['color'],
      isHidden: json['is_hidden'] ?? false,
    );
  }

  static const List<String> currencies = ['USD', 'EUR', 'FCFA'];
  static const List<String> types = ['bank', 'cash', 'mobile', 'wise', 'investment', 'other'];
}
