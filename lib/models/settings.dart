/// Business profile & app settings.
///
/// Mirrors the `settings` shape in `design/README.md`:
/// `{businessName,currency,lowStock,defaultMargin}`.
class AppSettings {
  final String businessName;
  final String currencyCode; // 'PHP' | 'USD'
  final int lowStockThreshold;
  final double defaultMargin;

  const AppSettings({
    this.businessName = "Aling Nena's Kitchen",
    this.currencyCode = 'PHP',
    this.lowStockThreshold = 10,
    this.defaultMargin = 40,
  });

  String get currencySymbol => currencyCode == 'USD' ? r'$' : '₱';

  AppSettings copyWith({
    String? businessName,
    String? currencyCode,
    int? lowStockThreshold,
    double? defaultMargin,
  }) {
    return AppSettings(
      businessName: businessName ?? this.businessName,
      currencyCode: currencyCode ?? this.currencyCode,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      defaultMargin: defaultMargin ?? this.defaultMargin,
    );
  }

  /// Write payload for Supabase — `user_id` defaults to `auth.uid()` on the
  /// server, so it's never sent from the client.
  Map<String, dynamic> toJson() => {
        'business_name': businessName,
        'currency_code': currencyCode,
        'low_stock_threshold': lowStockThreshold,
        'default_margin': defaultMargin,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        businessName: json['business_name'] as String? ?? "Aling Nena's Kitchen",
        currencyCode: json['currency_code'] as String? ?? 'PHP',
        lowStockThreshold: json['low_stock_threshold'] as int? ?? 10,
        defaultMargin: (json['default_margin'] as num?)?.toDouble() ?? 40,
      );
}
