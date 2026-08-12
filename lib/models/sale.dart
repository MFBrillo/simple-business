/// A recorded sale of a product.
///
/// Mirrors the `sales` shape in `design/README.md`: `{id,pid,qty,price,
/// method,date,day}`. `day` (0 = today) is derived from [date] rather than
/// stored, so it never goes stale.
class Sale {
  final int id;
  final int productId;
  final int qty;
  final double price;
  final String method;
  final DateTime date;

  const Sale({
    required this.id,
    required this.productId,
    required this.qty,
    required this.price,
    required this.method,
    required this.date,
  });

  /// Days since this sale, relative to [now] (0 = today).
  int dayOffset([DateTime? now]) {
    final today = _dateOnly(now ?? DateTime.now());
    return today.difference(_dateOnly(date)).inDays;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  double get revenue => price * qty;

  /// Write payload for Supabase — `id` is DB-assigned and never sent.
  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'qty': qty,
        'price': price,
        'method': method,
        'sold_at': date.toIso8601String(),
      };

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: json['id'] as int,
        productId: json['product_id'] as int,
        qty: json['qty'] as int,
        price: (json['price'] as num).toDouble(),
        method: json['method'] as String,
        date: DateTime.parse(json['sold_at'] as String),
      );
}

const kPaymentMethods = ['Cash', 'GCash', 'Bank Transfer', 'Other'];
