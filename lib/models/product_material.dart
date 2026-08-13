/// One ingredient line in a product's recipe — e.g. "Gulaman, ₱23/pack × 3".
/// A product's total material cost per unit is
/// `(Σ unitCost × quantity) ÷ batchYield` (see [Product.materials]).
class ProductMaterial {
  final String name;
  final double unitCost;
  final double quantity;

  const ProductMaterial({required this.name, required this.unitCost, required this.quantity});

  double get subtotal => unitCost * quantity;

  Map<String, dynamic> toJson() => {
        'name': name,
        'unit_cost': unitCost,
        'quantity': quantity,
      };

  factory ProductMaterial.fromJson(Map<String, dynamic> json) => ProductMaterial(
        name: json['name'] as String? ?? '',
        unitCost: (json['unit_cost'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      );
}
