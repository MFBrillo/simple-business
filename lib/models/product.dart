/// A product an owner sells, with its per-unit cost breakdown.
///
/// Mirrors the `products` shape in `design/README.md`:
/// `{id,name,cat,sku,price,mat,pack,labor,other,stock,unit}`.
class Product {
  final int id;
  final String name;
  final String category;
  final String sku;
  final double price;
  final double material;
  final double packaging;
  final double labor;
  final double other;
  final int stock;
  final String unit;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.sku,
    required this.price,
    required this.material,
    required this.packaging,
    required this.labor,
    required this.other,
    required this.stock,
    required this.unit,
  });

  /// `unitCost = material + packaging + labor + other`.
  double get unitCost => material + packaging + labor + other;

  /// `profitPerUnit = sellingPrice − unitCost`.
  double get profitPerUnit => price - unitCost;

  /// `margin % = profitPerUnit / sellingPrice × 100`. Zero when price is 0.
  double get marginPercent => price == 0 ? 0 : profitPerUnit / price * 100;

  /// `inventoryValue = unitCost × stock` for this product.
  double get inventoryValue => unitCost * stock;

  bool get isOutOfStock => stock <= 0;

  bool isLowStock(int threshold) => stock > 0 && stock <= threshold;

  Product copyWith({
    int? id,
    String? name,
    String? category,
    String? sku,
    double? price,
    double? material,
    double? packaging,
    double? labor,
    double? other,
    int? stock,
    String? unit,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      material: material ?? this.material,
      packaging: packaging ?? this.packaging,
      labor: labor ?? this.labor,
      other: other ?? this.other,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
    );
  }

  /// Write payload for Supabase — `id` is DB-assigned (identity column) and
  /// never sent on insert or update.
  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'sku': sku,
        'price': price,
        'material': material,
        'packaging': packaging,
        'labor': labor,
        'other': other,
        'stock': stock,
        'unit': unit,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        name: json['name'] as String,
        category: json['category'] as String,
        sku: json['sku'] as String,
        price: (json['price'] as num).toDouble(),
        material: (json['material'] as num).toDouble(),
        packaging: (json['packaging'] as num).toDouble(),
        labor: (json['labor'] as num).toDouble(),
        other: (json['other'] as num).toDouble(),
        stock: json['stock'] as int,
        unit: json['unit'] as String,
      );
}

/// Product categories offered in the "Category" select (Settings > Lists).
const kProductCategories = [
  'Desserts',
  'Main Dishes',
  'Beverages',
  'Snacks',
  'Other',
];

/// Units offered in the "Unit" select.
const kProductUnits = ['pc', 'cup', 'pack', 'kg', 'g', 'L', 'mL', 'box'];
