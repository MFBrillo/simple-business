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

  /// If set (and > 0), this expense also restocks that many units of the
  /// supply named after [description] — see `AppState.addExpense` /
  /// `supabase/005_supplies.sql`. Null for an expense that's just a cost,
  /// not a supply purchase.
  final int? quantity;

  /// Ties every row from one "Save batch as expense" click together, as
  /// `"<product_id>:<yyyy-MM-dd>"` — lets the Products form warn before
  /// saving the same product's ingredient batch twice in a day. Null for
  /// expenses added the normal way. See `AppState.saveIngredientBatchExpenses`
  /// / `supabase/006_expenses_batch_ref.sql`.
  final String? batchRef;

  const Expense({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
    this.notes = '',
    this.quantity,
    this.batchRef,
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
        'quantity': quantity,
        'batch_ref': batchRef,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as int,
        description: json['description'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['expense_date'] as String),
        notes: json['notes'] as String? ?? '',
        quantity: json['quantity'] as int?,
        batchRef: json['batch_ref'] as String?,
      );
}

/// Expense categories — the 8 from `design/README.md` plus `Ingredients`,
/// for raw materials bought for a recipe (sugar, gulaman, milk…) as
/// distinct from `Packaging`/`Supplies` (cups, spoons, bags…).
const kExpenseCategories = [
  'Ingredients',
  'Transportation',
  'Packaging',
  'Utilities',
  'Marketing',
  'Delivery',
  'Rent',
  'Supplies',
  'Miscellaneous',
];
