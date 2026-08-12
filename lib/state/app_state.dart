import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/sample_data.dart';
import '../models/expense.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/settings.dart';
import '../supabase/supabase_client.dart';
import 'app_screen.dart';

/// A pending confirm-dialog request (delete product, void sale, reset data…).
/// The Shell renders the actual dialog; screens just call [AppState.confirm].
class ConfirmRequest {
  final String title;
  final String body;
  final VoidCallback onConfirm;
  final String confirmLabel;
  const ConfirmRequest({
    required this.title,
    required this.body,
    required this.onConfirm,
    this.confirmLabel = 'Delete',
  });
}

/// Top-performing-product row, derived per render (never stored).
class ProductAggregate {
  final Product product;
  final int unitsSold;
  final double revenue;
  final double profit;
  const ProductAggregate({
    required this.product,
    required this.unitsSold,
    required this.revenue,
    required this.profit,
  });
}

/// Result of a sign-in/sign-up attempt — `success: false` covers both real
/// errors and informational outcomes (e.g. "check your email"); either way
/// the auth screen just surfaces [message] and stays put.
class AuthResult {
  final bool success;
  final String? message;
  const AuthResult.success() : success = true, message = null;
  const AuthResult.failure(this.message) : success = false;
}

/// Single source of truth for ProfitPilot. Products/sales/expenses/settings
/// live in Supabase, scoped per signed-in user by Row Level Security (see
/// `supabase/schema.sql`); this class mirrors the current auth session,
/// fetching on sign-in and clearing on sign-out. Theme is the only thing
/// still kept locally (device preference, not account data).
class AppState extends ChangeNotifier {
  static const _kThemeKey = 'pp_theme';

  SharedPreferences? _prefs;
  late final StreamSubscription<AuthState> _authSub;

  // --- Navigation / transient UI state -------------------------------
  AppScreen screen = AppScreen.dashboard;
  String search = '';
  int? editingId; // doubles as "selected product" for the detail screen

  ThemeMode themeMode = ThemeMode.light;

  String? toastMessage;
  Timer? _toastTimer;

  ConfirmRequest? confirmRequest;

  /// One-shot signal for "signed in but account isn't active" — set right
  /// before the forced sign-out, so the auth screen (which isn't wrapped by
  /// the in-app toast overlay) can show a snackbar for it. Screens that
  /// consume this should clear it back to null after showing it.
  String? accountLockedMessage;

  // --- Account-scoped data (Supabase) -----------------------------------
  List<Product> products = [];
  List<Sale> sales = [];
  List<Expense> expenses = [];
  AppSettings settings = const AppSettings();

  bool _loaded = false;
  bool get isLoaded => _loaded;

  bool get isAuthenticated => supabase.auth.currentSession != null;
  User? get currentUser => supabase.auth.currentUser;

  AppState() {
    _loadTheme();
    _authSub = supabase.auth.onAuthStateChange.listen(_onAuthStateChange);
  }

  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    final theme = _prefs!.getString(_kThemeKey);
    themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> _onAuthStateChange(AuthState data) async {
    if (data.session == null) {
      products = [];
      sales = [];
      expenses = [];
      settings = const AppSettings();
      screen = AppScreen.dashboard;
      _loaded = true;
      notifyListeners();
      return;
    }

    _loaded = false;
    notifyListeners();

    if (!await _isAccountActive()) {
      accountLockedMessage = "Your account isn't active yet. Contact your administrator to get access.";
      await supabase.auth.signOut(); // re-enters this method with session == null, which notifies
      return;
    }

    await _loadFromSupabase();
    _loaded = true;
    notifyListeners();
  }

  /// Checks the caller's `users.status` column. New sign-ups start at
  /// 'Inactive' (an approval gate, not just a lock) — an admin flips a row
  /// to 'Active' via the Supabase dashboard or a SQL statement to grant
  /// access; there's no in-app admin UI for this. Fails CLOSED: a missing
  /// row or any read error blocks access, matching the DB-level RLS check.
  Future<bool> _isAccountActive() async {
    try {
      final row = await supabase.from('users').select('status').maybeSingle();
      return row != null && row['status'] == 'Active';
    } catch (e) {
      return false;
    }
  }

  String _friendlyError(Object e) {
    if (e is AuthException) return e.message;
    if (e is PostgrestException) return e.message;
    return e.toString();
  }

  // --- Auth --------------------------------------------------------------
  Future<AuthResult> signInWithPassword(String email, String password) async {
    try {
      await supabase.auth.signInWithPassword(email: email, password: password);
      return const AuthResult.success();
    } catch (e) {
      return AuthResult.failure(_friendlyError(e));
    }
  }

  Future<AuthResult> signUpWithPassword(String email, String password) async {
    try {
      final res = await supabase.auth.signUp(email: email, password: password);
      if (res.session == null) {
        return const AuthResult.failure('Account created — check your email to confirm it, then sign in.');
      }
      return const AuthResult.success();
    } catch (e) {
      return AuthResult.failure(_friendlyError(e));
    }
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      showToast('Could not sign out: ${_friendlyError(e)}');
    }
  }

  // --- Loading data --------------------------------------------------------
  Future<void> _loadFromSupabase() async {
    try {
      final productRows = await supabase.from('products').select().order('created_at');
      products = productRows.map((r) => Product.fromJson(r)).toList();

      final salesRows = await supabase.from('sales').select().order('sold_at', ascending: false);
      sales = salesRows.map((r) => Sale.fromJson(r)).toList();

      final expenseRows = await supabase.from('expenses').select().order('expense_date', ascending: false);
      expenses = expenseRows.map((r) => Expense.fromJson(r)).toList();

      final settingsRows = await supabase.from('settings').select().limit(1);
      if (settingsRows.isEmpty) {
        settings = const AppSettings();
        await supabase.from('settings').upsert(settings.toJson());
        if (products.isEmpty) await _seedSampleData();
      } else {
        settings = AppSettings.fromJson(settingsRows.first);
      }
    } catch (e) {
      showToast('Could not load your data: ${_friendlyError(e)}');
    }
  }

  /// Inserts the sample dataset, remapping sample sales' product references
  /// from the sample's own ids to whatever ids Supabase actually assigns.
  Future<void> _seedSampleData() async {
    final sampleProducts = SampleData.products();
    final productRows = await supabase.from('products').insert([for (final p in sampleProducts) p.toJson()]).select();
    final insertedProducts = productRows.map((r) => Product.fromJson(r)).toList();
    final idMap = <int, int>{
      for (var i = 0; i < sampleProducts.length; i++) sampleProducts[i].id: insertedProducts[i].id,
    };

    final salesPayload = [
      for (final s in SampleData.sales()) {...s.toJson(), 'product_id': idMap[s.productId]},
    ];
    final salesRows = await supabase.from('sales').insert(salesPayload).select();

    final expenseRows = await supabase.from('expenses').insert([for (final e in SampleData.expenses()) e.toJson()]).select();

    products = insertedProducts;
    sales = salesRows.map((r) => Sale.fromJson(r)).toList()..sort((a, b) => b.date.compareTo(a.date));
    expenses = expenseRows.map((r) => Expense.fromJson(r)).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  // --- Navigation --------------------------------------------------------
  void goTo(AppScreen next, {int? productId}) {
    screen = next;
    if (productId != null) editingId = productId;
    notifyListeners();
  }

  /// Opens the Add Product form with a blank `editingId` (new product).
  void startAddProduct() {
    editingId = null;
    goTo(AppScreen.addProduct);
  }

  /// Opens the Add Product form pre-loaded with an existing product.
  void startEditProduct(int id) => goTo(AppScreen.addProduct, productId: id);

  /// Opens Product Details for the given product.
  void viewProduct(int id) => goTo(AppScreen.detail, productId: id);

  void setSearch(String value) {
    search = value;
    notifyListeners();
  }

  // --- Theme ---------------------------------------------------------------
  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _prefs?.setString(_kThemeKey, themeMode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  // --- Toasts ----------------------------------------------------------
  void showToast(String message) {
    _toastTimer?.cancel();
    toastMessage = message;
    notifyListeners();
    _toastTimer = Timer(const Duration(milliseconds: 2600), () {
      toastMessage = null;
      notifyListeners();
    });
  }

  // --- Confirm dialogs -----------------------------------------------------
  void confirm({
    required String title,
    required String body,
    required VoidCallback onConfirm,
    String confirmLabel = 'Delete',
  }) {
    confirmRequest = ConfirmRequest(title: title, body: body, onConfirm: onConfirm, confirmLabel: confirmLabel);
    notifyListeners();
  }

  void dismissConfirm() {
    confirmRequest = null;
    notifyListeners();
  }

  void acceptConfirm() {
    confirmRequest?.onConfirm();
    confirmRequest = null;
    notifyListeners();
  }

  // --- Products --------------------------------------------------------
  Product? productById(int id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Inserts or updates [product] in Supabase. `product.id` is ignored on
  /// insert (DB-assigned); pass any placeholder (e.g. `0`) for new products.
  Future<bool> saveProduct(Product product, {required bool isNew}) async {
    try {
      final Map<String, dynamic> row;
      if (isNew) {
        row = await supabase.from('products').insert(product.toJson()).select().single();
      } else {
        row = await supabase.from('products').update(product.toJson()).eq('id', product.id).select().single();
      }
      final saved = Product.fromJson(row);
      if (isNew) {
        products.insert(0, saved);
      } else {
        final i = products.indexWhere((p) => p.id == saved.id);
        if (i != -1) products[i] = saved;
      }
      notifyListeners();
      return true;
    } catch (e) {
      showToast('Could not save product: ${_friendlyError(e)}');
      return false;
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await supabase.from('products').delete().eq('id', id);
      products.removeWhere((p) => p.id == id);
      notifyListeners();
      showToast('Product deleted');
    } catch (e) {
      showToast('Could not delete product: ${_friendlyError(e)}');
    }
  }

  // --- Sales -----------------------------------------------------------
  /// Records a sale and decrements stock (floored at 0). Returns the profit
  /// earned, or null if blocked (qty <= 0) or the write failed.
  Future<double?> recordSale({
    required int productId,
    required int qty,
    required double price,
    required String method,
  }) async {
    if (qty <= 0) return null;
    final product = productById(productId);
    if (product == null) return null;

    try {
      final draft = Sale(id: 0, productId: productId, qty: qty, price: price, method: method, date: DateTime.now());
      final saleRow = await supabase.from('sales').insert(draft.toJson()).select().single();
      sales.insert(0, Sale.fromJson(saleRow));

      final newStock = (product.stock - qty).clamp(0, 1 << 30);
      final productRow = await supabase.from('products').update({'stock': newStock}).eq('id', productId).select().single();
      final updatedProduct = Product.fromJson(productRow);
      final i = products.indexWhere((p) => p.id == productId);
      if (i != -1) products[i] = updatedProduct;

      notifyListeners();
      return (price - product.unitCost) * qty;
    } catch (e) {
      showToast('Could not record sale: ${_friendlyError(e)}');
      return null;
    }
  }

  Future<void> voidSale(int id) async {
    try {
      await supabase.from('sales').delete().eq('id', id);
      sales.removeWhere((s) => s.id == id);
      notifyListeners();
      showToast('Sale voided');
    } catch (e) {
      showToast('Could not void sale: ${_friendlyError(e)}');
    }
  }

  // --- Expenses ----------------------------------------------------------
  Future<bool> addExpense(Expense expense) async {
    try {
      final row = await supabase.from('expenses').insert(expense.toJson()).select().single();
      expenses.insert(0, Expense.fromJson(row));
      notifyListeners();
      return true;
    } catch (e) {
      showToast('Could not add expense: ${_friendlyError(e)}');
      return false;
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await supabase.from('expenses').delete().eq('id', id);
      expenses.removeWhere((e) => e.id == id);
      notifyListeners();
      showToast('Expense deleted');
    } catch (e) {
      showToast('Could not delete expense: ${_friendlyError(e)}');
    }
  }

  // --- Settings ------------------------------------------------------------
  Future<void> updateSettings(AppSettings next) async {
    final previous = settings;
    settings = next; // optimistic — sliders/text fields should feel instant
    notifyListeners();
    try {
      await supabase.from('settings').upsert(next.toJson());
    } catch (e) {
      settings = previous;
      notifyListeners();
      showToast('Could not save settings: ${_friendlyError(e)}');
    }
  }

  Future<void> resetSampleData() async {
    try {
      await supabase.from('sales').delete().neq('id', -1);
      await supabase.from('expenses').delete().neq('id', -1);
      await supabase.from('products').delete().neq('id', -1);
      await _seedSampleData();
      notifyListeners();
      showToast('Sample data restored');
    } catch (e) {
      showToast('Could not reset data: ${_friendlyError(e)}');
    }
  }

  // --- Derived: today / month --------------------------------------------
  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isThisMonth(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month;
  }

  Iterable<Sale> get _todaySales => sales.where((s) => _isToday(s.date));
  Iterable<Sale> get _monthSales => sales.where((s) => _isThisMonth(s.date));
  Iterable<Expense> get _todayExpenses => expenses.where((e) => _isToday(e.date));
  Iterable<Expense> get _monthExpenses => expenses.where((e) => _isThisMonth(e.date));

  double _saleCost(Sale s) => (productById(s.productId)?.unitCost ?? 0) * s.qty;
  double _saleProfit(Sale s) => s.revenue - _saleCost(s);

  double get todaySalesTotal => _todaySales.fold(0.0, (sum, s) => sum + s.revenue);
  double get todayProfitTotal => _todaySales.fold(0.0, (sum, s) => sum + _saleProfit(s));
  double get todayExpensesTotal => _todayExpenses.fold(0.0, (sum, e) => sum + e.amount);
  int get todayItemsSold => _todaySales.fold(0, (sum, s) => sum + s.qty);

  double get inventoryValue => products.fold(0.0, (sum, p) => sum + p.inventoryValue);

  double get monthSalesProfit => _monthSales.fold(0.0, (sum, s) => sum + _saleProfit(s));
  double get monthExpensesTotal => _monthExpenses.fold(0.0, (sum, e) => sum + e.amount);

  /// `monthNet = Σ sales profit − Σ expenses` — red styling when negative.
  double get monthNet => monthSalesProfit - monthExpensesTotal;

  int get lowStockCount =>
      products.where((p) => p.isLowStock(settings.lowStockThreshold)).length;
  int get outOfStockCount => products.where((p) => p.isOutOfStock).length;

  /// Top performing products by revenue (all-time), for the Dashboard table.
  List<ProductAggregate> topProducts({int limit = 5}) {
    final byProduct = <int, List<Sale>>{};
    for (final s in sales) {
      byProduct.putIfAbsent(s.productId, () => []).add(s);
    }
    final aggregates = <ProductAggregate>[];
    for (final entry in byProduct.entries) {
      final product = productById(entry.key);
      if (product == null) continue;
      final units = entry.value.fold(0, (sum, s) => sum + s.qty);
      final revenue = entry.value.fold(0.0, (sum, s) => sum + s.revenue);
      final profit = entry.value.fold(0.0, (sum, s) => sum + _saleProfit(s));
      aggregates.add(ProductAggregate(product: product, unitsSold: units, revenue: revenue, profit: profit));
    }
    aggregates.sort((a, b) => b.revenue.compareTo(a.revenue));
    return aggregates.take(limit).toList();
  }

  /// Sales, cost & profit per day for the last [days] days (0 = today first).
  List<({DateTime day, double sales, double cost, double profit})> dailyTotals({int days = 7}) {
    final result = <({DateTime day, double sales, double cost, double profit})>[];
    final today = DateTime.now();
    for (var i = days - 1; i >= 0; i--) {
      final day = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
      final daySales = sales.where((s) =>
          s.date.year == day.year && s.date.month == day.month && s.date.day == day.day);
      final salesTotal = daySales.fold(0.0, (sum, s) => sum + s.revenue);
      final costTotal = daySales.fold(0.0, (sum, s) => sum + _saleCost(s));
      result.add((day: day, sales: salesTotal, cost: costTotal, profit: salesTotal - costTotal));
    }
    return result;
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _authSub.cancel();
    super.dispose();
  }
}
