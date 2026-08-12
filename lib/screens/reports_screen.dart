import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../utils/formatting.dart';
import '../widgets/bar_chart.dart';
import '../widgets/kpi_card.dart';
import '../widgets/section_card.dart';

const _dateRanges = ['Last 7 days', 'Last 30 days', 'All time'];

/// Filters here mirror the design prototype: selecting one just confirms
/// with a toast (the mock doesn't actually re-slice the sample data) —
/// KPIs and charts below always summarize all recorded activity.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String range = _dateRanges.first;
  String product = 'All products';
  String category = 'All categories';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final colors = context.colors;
    final symbol = state.settings.currencySymbol;

    final totalSales = state.sales.fold(0.0, (sum, s) => sum + s.revenue);
    final totalCost = state.sales.fold(0.0, (sum, s) => sum + (state.productById(s.productId)?.unitCost ?? 0) * s.qty);
    final totalProfit = totalSales - totalCost;
    final avgMargin = totalSales == 0 ? 0.0 : totalProfit / totalSales * 100;
    final unitsSold = state.sales.fold(0, (sum, s) => sum + s.qty);

    final daily = state.dailyTotals();
    final groups = [
      for (final d in daily) BarGroup(dayLabel: formatShortDay(d.day), values: [d.sales, d.profit])
    ];

    final topProducts = state.topProducts(limit: 6);
    final profitByProduct = [
      for (final agg in topProducts) HBarItem(label: agg.product.name, value: agg.profit, color: colors.green),
    ];

    final byExpenseCategory = <String, double>{};
    for (final e in state.expenses) {
      byExpenseCategory[e.category] = (byExpenseCategory[e.category] ?? 0) + e.amount;
    }
    final expenseColors = [colors.amber, colors.red, colors.bar];
    final expenseItems = byExpenseCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final expenseBars = [
      for (var i = 0; i < expenseItems.length; i++)
        HBarItem(label: expenseItems[i].key, value: expenseItems[i].value, color: expenseColors[i % expenseColors.length]),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              _FilterSelect(
                value: range,
                items: _dateRanges,
                onChanged: (v) {
                  setState(() => range = v);
                  state.showToast('Showing $v');
                },
              ),
              _FilterSelect(
                value: product,
                items: ['All products', ...state.products.map((p) => p.name)],
                onChanged: (v) {
                  setState(() => product = v);
                  state.showToast('Filtered to $v');
                },
              ),
              _FilterSelect(
                value: category,
                items: ['All categories', ...kProductCategories],
                onChanged: (v) {
                  setState(() => category = v);
                  state.showToast('Filtered to $v');
                },
              ),
              _ExportButton(label: 'Export PDF', onTap: () => state.showToast('Exported report as PDF')),
              _ExportButton(label: 'Export Excel', onTap: () => state.showToast('Exported report as Excel')),
              _ExportButton(label: 'Print', onTap: () => state.showToast('Sent to printer')),
            ],
          ),
        ),
        const SizedBox(height: 20),
        KpiGrid(cards: [
          KpiCard(label: 'Total sales', value: formatMoney(totalSales, symbol)),
          KpiCard(label: 'Total cost', value: formatMoney(totalCost, symbol), valueColor: colors.amber),
          KpiCard(label: 'Total profit', value: formatMoney(totalProfit, symbol), valueColor: colors.greenInk),
          KpiCard(label: 'Average margin', value: '${avgMargin.toStringAsFixed(1)}%'),
          KpiCard(label: 'Units sold', value: '$unitsSold'),
        ]),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: SectionTitle(title: 'Sales & profit trend', subtitle: 'Last 7 days')),
                  ChartLegend(items: [('Sales', colors.bar), ('Profit', colors.green)]),
                ],
              ),
              const SizedBox(height: 18),
              GroupedBarChart(groups: groups, seriesColors: [colors.bar, colors.green]),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 680;
            final profitCard = SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Profit by product'),
                  const SizedBox(height: 16),
                  if (profitByProduct.isEmpty)
                    Text('No sales yet.', style: TextStyle(color: colors.muted, fontSize: 13))
                  else
                    HorizontalBarChart(items: profitByProduct, formatValue: (v) => formatMoney(v, symbol)),
                ],
              ),
            );
            final expenseCard = SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Expense breakdown'),
                  const SizedBox(height: 16),
                  if (expenseBars.isEmpty)
                    Text('No expenses yet.', style: TextStyle(color: colors.muted, fontSize: 13))
                  else
                    HorizontalBarChart(items: expenseBars, formatValue: (v) => formatMoney(v, symbol)),
                ],
              ),
            );
            if (stacked) {
              return Column(children: [profitCard, const SizedBox(height: 20), expenseCard]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: profitCard), const SizedBox(width: 20), Expanded(child: expenseCard)],
            );
          },
        ),
      ],
    );
  }
}

class _FilterSelect extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  const _FilterSelect({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        style: TextStyle(fontSize: 12.5, color: colors.ink),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: colors.bg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field), borderSide: BorderSide(color: colors.line)),
        ),
        items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ExportButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.ink2,
        side: BorderSide(color: colors.line),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12.5)),
    );
  }
}
