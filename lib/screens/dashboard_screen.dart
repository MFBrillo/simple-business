import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../models/sale.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../utils/formatting.dart';
import '../widgets/bar_chart.dart';
import '../widgets/kpi_card.dart';
import '../widgets/section_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final colors = context.colors;
    final symbol = state.settings.currencySymbol;

    final daily = state.dailyTotals();
    final groups = [
      for (final d in daily) BarGroup(dayLabel: formatShortDay(d.day), values: [d.sales, d.cost, d.profit])
    ];
    final topProducts = state.topProducts();
    final recent = <_RecentEntry>[
      ...state.sales.take(6).map((s) => (isExpense: false, date: s.date, sale: s, expense: null)),
      ...state.expenses.take(6).map((e) => (isExpense: true, date: e.date, sale: null, expense: e)),
    ]..sort((a, b) => b.date.compareTo(a.date));
    final recentTop = recent.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KpiGrid(cards: [
          KpiCard(label: "Today's sales", value: formatMoney(state.todaySalesTotal, symbol)),
          KpiCard(label: "Today's profit", value: formatMoney(state.todayProfitTotal, symbol), valueColor: colors.greenInk),
          KpiCard(label: "Today's expenses", value: formatMoney(state.todayExpensesTotal, symbol), valueColor: colors.red),
          KpiCard(label: 'Items sold', value: '${state.todayItemsSold}'),
          KpiCard(label: 'Inventory value', value: formatMoney(state.inventoryValue, symbol)),
        ]),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: SectionTitle(title: 'Sales, cost & profit', subtitle: 'Last 7 days'),
                  ),
                  ChartLegend(items: [
                    ('Sales', colors.bar),
                    ('Cost', colors.amber),
                    ('Profit', colors.green),
                  ]),
                ],
              ),
              const SizedBox(height: 18),
              GroupedBarChart(groups: groups, seriesColors: [colors.bar, colors.amber, colors.green]),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Top performing products'),
              const SizedBox(height: 14),
              if (topProducts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('No sales yet.', style: TextStyle(color: colors.muted, fontSize: 13)),
                )
              else ...[
                _TableHeader(colors: colors),
                for (final agg in topProducts)
                  _TopProductRow(agg: agg, symbol: symbol),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Recent transactions'),
              const SizedBox(height: 14),
              if (recentTop.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('Nothing recorded yet.', style: TextStyle(color: colors.muted, fontSize: 13)),
                )
              else
                for (final entry in recentTop) _TransactionRow(entry: entry, symbol: symbol),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final AppColors colors;
  const _TableHeader({required this.colors});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: colors.muted, letterSpacing: 0.05);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('PRODUCT', style: style)),
          Expanded(flex: 1, child: Text('UNITS', style: style, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('REVENUE', style: style, textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('PROFIT', style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _TopProductRow extends StatelessWidget {
  final ProductAggregate agg;
  final String symbol;
  const _TopProductRow({required this.agg, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.line))),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agg.product.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.ink)),
                Text(agg.product.category, style: TextStyle(fontSize: 11, color: colors.muted)),
              ],
            ),
          ),
          Expanded(flex: 1, child: Text('${agg.unitsSold}', textAlign: TextAlign.right, style: TextStyle(color: colors.ink2, fontSize: 13))),
          Expanded(
            flex: 2,
            child: Text(formatMoney(agg.revenue, symbol), textAlign: TextAlign.right, style: TextStyle(color: colors.ink2, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatMoney(agg.profit, symbol),
              textAlign: TextAlign.right,
              style: TextStyle(color: colors.greenInk, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _RecentEntry = ({bool isExpense, DateTime date, Sale? sale, Expense? expense});

class _TransactionRow extends StatelessWidget {
  final _RecentEntry entry;
  final String symbol;
  const _TransactionRow({required this.entry, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = context.read<AppState>();
    final isExpense = entry.isExpense;

    String title;
    String meta;
    double amount;
    if (isExpense) {
      final e = entry.expense!;
      title = e.description;
      meta = e.category;
      amount = -e.amount;
    } else {
      final s = entry.sale!;
      final product = state.productById(s.productId);
      title = product?.name ?? 'Product';
      meta = '${s.qty} × ${formatMoney(s.price, symbol)}';
      amount = s.revenue;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isExpense ? colors.redSoft : colors.greenSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isExpense ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 16,
              color: isExpense ? colors.red : colors.greenInk,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.ink)),
                Text(meta, style: TextStyle(fontSize: 11.5, color: colors.muted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? '−' : '+'}${formatMoney(amount.abs(), symbol)}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isExpense ? colors.red : colors.greenInk,
                ),
              ),
              Text(formatDateLabel(entry.date), style: TextStyle(fontSize: 11, color: colors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}
