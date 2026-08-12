import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/app_screen.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../utils/formatting.dart';
import '../widgets/add_stock_dialog.dart';
import '../widgets/bar_chart.dart';
import '../widgets/section_card.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final colors = context.colors;
    final product = state.editingId == null ? null : state.productById(state.editingId!);

    if (product == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackLink(),
          const SizedBox(height: 20),
          Text('Product not found.', style: TextStyle(color: colors.muted)),
        ],
      );
    }

    final symbol = state.settings.currencySymbol;
    final sales = state.sales.where((s) => s.productId == product.id).toList();
    final totalUnits = sales.fold(0, (sum, s) => sum + s.qty);
    final totalRevenue = sales.fold(0.0, (sum, s) => sum + s.revenue);
    final totalCost = totalUnits * product.unitCost;
    final totalProfit = totalRevenue - totalCost;

    final daily = state.dailyTotals();
    final groups = [
      for (final d in daily)
        BarGroup(
          dayLabel: formatShortDay(d.day),
          values: [
            sales
                .where((s) => s.date.year == d.day.year && s.date.month == d.day.month && s.date.day == d.day.day)
                .fold(0.0, (sum, s) => sum + s.revenue),
            sales
                .where((s) => s.date.year == d.day.year && s.date.month == d.day.month && s.date.day == d.day.day)
                .fold(0.0, (sum, s) => sum + (s.revenue - s.qty * product.unitCost)),
          ],
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BackLink(),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 680;
            final left = _LeftCard(product: product, symbol: symbol);
            final right = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: 'Sales performance'),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _FactTile(label: 'Total units sold', value: '$totalUnits'),
                          _FactTile(label: 'Total revenue', value: formatMoney(totalRevenue, symbol)),
                          _FactTile(label: 'Total cost', value: formatMoney(totalCost, symbol), color: colors.amber),
                          _FactTile(label: 'Total profit', value: formatMoney(totalProfit, symbol), color: colors.greenInk),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: SectionTitle(title: 'Sales & profit over time')),
                          ChartLegend(items: [('Sales', colors.bar), ('Profit', colors.green)]),
                        ],
                      ),
                      const SizedBox(height: 18),
                      GroupedBarChart(groups: groups, seriesColors: [colors.bar, colors.green], maxHeight: 130),
                    ],
                  ),
                ),
              ],
            );

            if (stacked) {
              return Column(children: [left, const SizedBox(height: 20), right]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: right),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: () => context.read<AppState>().goTo(AppScreen.products),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back, size: 16, color: colors.muted),
          const SizedBox(width: 6),
          Text('Back to Products', style: TextStyle(color: colors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LeftCard extends StatelessWidget {
  final Product product;
  final String symbol;
  const _LeftCard({required this.product, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = context.read<AppState>();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.hover,
              borderRadius: BorderRadius.circular(AppRadius.tileLg),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image_outlined, color: colors.muted, size: 26),
                const SizedBox(height: 8),
                Text('product shot → drop image here', style: plexMonoCaption(context)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(product.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.ink)),
          const SizedBox(height: 4),
          Text(
            '${product.category} · ${product.sku} · ${product.stock} ${product.unit} on hand',
            style: TextStyle(fontSize: 12.5, color: colors.muted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _FactTile(label: 'Selling price', value: formatMoney(product.price, symbol, decimals: 2)),
              _FactTile(label: 'Unit cost', value: formatMoney(product.unitCost, symbol, decimals: 2), color: colors.amber),
              _FactTile(label: 'Profit/unit', value: formatMoney(product.profitPerUnit, symbol, decimals: 2), color: colors.greenInk),
              _FactTile(label: 'Margin', value: '${product.marginPercent.toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => state.startEditProduct(product.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                  ),
                  child: const Text('Edit product'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => showAddStockDialog(context, product),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.ink2,
                    side: BorderSide(color: colors.line),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                  ),
                  child: const Text('Add stock'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FactTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _FactTile({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(AppRadius.tile)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: colors.muted)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color ?? colors.ink)),
        ],
      ),
    );
  }
}
