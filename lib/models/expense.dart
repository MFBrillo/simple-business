/// A logged business expense.
///
/// Mirrors the `expenses` shape in `design/README.md`:
/// `{id,desc,cat,amount,date,notes}`.
class Expense {
  final int id;
  final String description;
  final String category;
  final double amount;
  final DateTime date;
  final String notes;

  const Expense({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
    this.notes = '',
  });

  /// Write payload for Supabase — `id` is DB-assigned and never sent.
  /// `expense_date` is a plain SQL `date` column, so only the date portion
  /// is sent (no time-of-day/timezone).
  Map<String, dynamic> toJson() => {
        'description': description,
        'category': category,
        'amount': amount,
        'expense_date': date.toIso8601String().split('T').first,
        'notes': notes,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as int,
        description: json['description'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['expense_date'] as String),
        notes: json['notes'] as String? ?? '',
      );
}

/// The 8 expense categories from `design/README.md`.
const kExpenseCategories = [
  'Transportation',
  'Packaging',
  'Utilities',
  'Marketing',
  'Delivery',
  'Rent',
  'Supplies',
  'Miscellaneous',
];
