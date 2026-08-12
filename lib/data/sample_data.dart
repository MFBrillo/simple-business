import '../models/expense.dart';
import '../models/product.dart';
import '../models/sale.dart';

/// Seed data for "Aling Nena's Kitchen" — ported from `design/README.md`.
/// Exists only to exercise every UI state (in stock / low / out of stock,
/// positive / negative month); replace with real persisted data.
class SampleData {
  SampleData._();

  static List<Product> products() => [
        const Product(
          id: 1,
          name: 'Gulaman Jelly',
          category: 'Desserts',
          sku: 'GUL-001',
          price: 15,
          material: 4,
          packaging: 1.5,
          labor: 2,
          other: 0.5,
          stock: 40,
          unit: 'cup',
        ),
        const Product(
          id: 2,
          name: 'Special Burger',
          category: 'Main Dishes',
          sku: 'BRG-002',
          price: 50,
          material: 22,
          packaging: 3,
          labor: 8,
          other: 1,
          stock: 25,
          unit: 'pc',
        ),
        const Product(
          id: 3,
          name: 'Wintermelon Milk Tea',
          category: 'Beverages',
          sku: 'WMT-003',
          price: 50,
          material: 20,
          packaging: 4,
          labor: 5,
          other: 1,
          stock: 8, // low stock (<= default threshold of 10)
          unit: 'cup',
        ),
        const Product(
          id: 4,
          name: 'Buko Pandan',
          category: 'Desserts',
          sku: 'BKP-004',
          price: 45,
          material: 16,
          packaging: 3,
          labor: 5,
          other: 1,
          stock: 0, // out of stock
          unit: 'cup',
        ),
        const Product(
          id: 5,
          name: 'Siomai 4pcs',
          category: 'Snacks',
          sku: 'SIO-005',
          price: 30,
          material: 11,
          packaging: 2,
          labor: 3,
          other: 1,
          stock: 60,
          unit: 'pack',
        ),
        const Product(
          id: 6,
          name: 'Puto Cheese',
          category: 'Desserts',
          sku: 'PUT-006',
          price: 12,
          material: 4,
          packaging: 1,
          labor: 1.2,
          other: 0.3,
          stock: 100,
          unit: 'pc',
        ),
      ];

  /// 14 sales spread across the last 8 days (0 = today).
  static List<Sale> sales() {
    DateTime at(int dayOffset, int hour, int minute) {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: dayOffset));
      return DateTime(day.year, day.month, day.day, hour, minute);
    }

    return [
      Sale(id: 1, productId: 1, qty: 3, price: 15, method: 'Cash', date: at(0, 9, 10)),
      Sale(id: 2, productId: 2, qty: 2, price: 50, method: 'GCash', date: at(0, 11, 45)),
      Sale(id: 3, productId: 5, qty: 4, price: 30, method: 'Cash', date: at(0, 14, 40)),
      Sale(id: 4, productId: 3, qty: 2, price: 50, method: 'Bank Transfer', date: at(1, 10, 5)),
      Sale(id: 5, productId: 6, qty: 6, price: 12, method: 'Cash', date: at(1, 16, 20)),
      Sale(id: 6, productId: 2, qty: 1, price: 50, method: 'Cash', date: at(2, 12, 0)),
      Sale(id: 7, productId: 1, qty: 5, price: 15, method: 'GCash', date: at(2, 17, 30)),
      Sale(id: 8, productId: 5, qty: 3, price: 30, method: 'Cash', date: at(3, 9, 50)),
      Sale(id: 9, productId: 4, qty: 2, price: 45, method: 'Cash', date: at(3, 13, 15)),
      Sale(id: 10, productId: 6, qty: 4, price: 12, method: 'GCash', date: at(4, 10, 40)),
      Sale(id: 11, productId: 3, qty: 3, price: 50, method: 'Cash', date: at(5, 11, 25)),
      Sale(id: 12, productId: 2, qty: 2, price: 50, method: 'Other', date: at(5, 15, 5)),
      Sale(id: 13, productId: 1, qty: 4, price: 15, method: 'Cash', date: at(6, 9, 35)),
      Sale(id: 14, productId: 5, qty: 2, price: 30, method: 'Bank Transfer', date: at(7, 14, 0)),
    ];
  }

  /// 7 expenses; "Rent" is the largest category.
  static List<Expense> expenses() {
    DateTime at(int dayOffset) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: dayOffset));
    }

    return [
      Expense(id: 1, description: 'Tricycle fare for market run', category: 'Transportation', amount: 150, date: at(0), notes: ''),
      Expense(id: 2, description: 'Cups and takeout boxes', category: 'Packaging', amount: 320, date: at(1), notes: ''),
      Expense(id: 3, description: 'Electricity bill share', category: 'Utilities', amount: 850, date: at(2), notes: ''),
      Expense(id: 4, description: 'Facebook ad boost', category: 'Marketing', amount: 200, date: at(2), notes: ''),
      Expense(id: 5, description: 'Lalamove delivery fee', category: 'Delivery', amount: 180, date: at(3), notes: ''),
      Expense(id: 6, description: 'Weekly stall rent', category: 'Rent', amount: 1500, date: at(4), notes: ''),
      Expense(id: 7, description: 'Extra ice and condiments', category: 'Supplies', amount: 260, date: at(5), notes: ''),
    ];
  }
}
