import 'package:intl/intl.dart';

/// `₱` + `toLocaleString('en-PH')` per `design/README.md`.
/// 2 decimals for unit values, 0 decimals for summary figures.
String formatMoney(double amount, String symbol, {int decimals = 0}) {
  final formatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: symbol,
    decimalDigits: decimals,
  );
  return formatter.format(amount);
}

String formatDateLabel(DateTime date) {
  final now = DateTime.now();
  final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
  final yesterday = now.subtract(const Duration(days: 1));
  final isYesterday =
      date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  final time = DateFormat('h:mm a').format(date);
  if (isToday) return 'Today, $time';
  if (isYesterday) return 'Yesterday, $time';
  return '${DateFormat('MMM d').format(date)}, $time';
}

String formatShortDay(DateTime date) => DateFormat('EEE').format(date);
