/// A trackable packaging/consumable supply (e.g. "Plastic Cup", "Spoon").
/// Restocked via an [Expense]'s optional `quantity` (see
/// `AppState.addExpense`); drops by 1 per recorded sale, regardless of
/// which product was sold (see `AppState.recordSale`).
class Supply {
  final int id;
  final String name;
  final int quantity;

  const Supply({required this.id, required this.name, required this.quantity});

  Map<String, dynamic> toJson() => {'name': name, 'quantity': quantity};

  factory Supply.fromJson(Map<String, dynamic> json) => Supply(
        id: json['id'] as int,
        name: json['name'] as String,
        quantity: json['quantity'] as int,
      );
}
