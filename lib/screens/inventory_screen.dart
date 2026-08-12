import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../utils/formatting.dart';
import '../widgets/add_stock_dialog.dart';
import '../widgets/kpi_card.dart';
import '../widgets/section_card.dart';
import '../widgets/status_pill.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final colors = context.colors;
    final symbol = state.settings.currencySymbol;
    final threshold = state.settings.lowStockThreshold;

    final totalStock = state.products.fold(0, (sum, p) => sum + p.stock);
    final atRiskCount = state.lowStockCount + state.outOfStockCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KpiGrid(cards: [
          KpiCard(label: 'Total products', value: '${state.products.length}'),
          KpiCard(label: 'Total stock', value: '$totalStock'),
          KpiCard(label: 'Low/out of stock', value: '$atRiskCount', valueColor: colors.amber),
          KpiCard(label: 'Inventory value', value: formatMoney(state.inventoryValue, symbol), valueColor: colors.greenInk),
        ]),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: SectionTitle(title: 'Inventory')),
                  Text('Low-stock threshold: $threshold', style: TextStyle(fontSize: 12, color: colors.muted)),
                ],
              ),
              const SizedBox(height: 14),
              if (state.products.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('No products yet.', style: TextStyle(color: colors.muted, fontSize: 13)),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 700),
                    child: Column(
                      children: [
                        _Header(colors: colors),
                        for (final p in state.products) _Row(product: p, symbol: symbol, threshold: threshold),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final AppColors colors;
  const _Header({required this.colors});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: colors.muted, letterSpacing: 0.05);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 200, child: Text('PRODUCT', style: style)),
          SizedBox(width: 60, child: Text('STOCK', style: style, textAlign: TextAlign.right)),
          SizedBox(width: 60, child: Text('UNIT', style: style)),
          SizedBox(width: 90, child: Text('COST/UNIT', style: style, textAlign: TextAlign.right)),
          SizedBox(width: 110, child: Text('VALUE', style: style, textAlign: TextAlign.right)),
          SizedBox(width: 100, child: Text('STATUS', style: style)),
          const SizedBox(width: 170),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final Product product;
  final String symbol;
  final int threshold;
  const _Row({required this.product, required this.symbol, required this.threshold});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = context.read<AppState>();
    final (label, tone) = product.isOutOfStock
        ? ('Out of stock', PillTone.red)
        : product.isLowStock(threshold)
            ? ('Low stock', PillTone.amber)
            : ('In stock', PillTone.green);

    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.line))),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.ink)),
                Text(product.category, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: colors.muted)),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: Text('${product.stock}', textAlign: TextAlign.right, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: colors.ink)),
          ),
          SizedBox(width: 60, child: Text(product.unit, style: TextStyle(fontSize: 12.5, color: colors.ink2))),
          SizedBox(
            width: 90,
            child: Text(formatMoney(product.unitCost, symbol, decimals: 2), textAlign: TextAlign.right, style: TextStyle(fontSize: 12.5, color: colors.ink2)),
          ),
          SizedBox(
            width: 110,
            child: Text(formatMoney(product.inventoryValue, symbol), textAlign: TextAlign.right, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.ink)),
          ),
          SizedBox(width: 100, child: StatusPill(label: label, tone: tone)),
          SizedBox(
            width: 170,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => showAddStockDialog(context, product),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.ink2,
                      side: BorderSide(color: colors.line),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                    ),
                    child: const Text('Add stock', style: TextStyle(fontSize: 11.5)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => state.viewProduct(product.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.ink2,
                      side: BorderSide(color: colors.line),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                    ),
                    child: const Text('History', style: TextStyle(fontSize: 11.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
