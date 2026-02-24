class Asset {
  final int id;
  final String name;
  final String type;
  final double value;
  final String currency;
  final double? quantity;
  final String? notes;

  Asset({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.currency,
    this.quantity,
    this.notes,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      value: (json['value'] ?? 0).toDouble(),
      currency: json['currency'],
      quantity: json['quantity']?.toDouble(),
      notes: json['notes'],
    );
  }

  static const List<String> types = ['property', 'gold', 'commodity', 'other'];
}
