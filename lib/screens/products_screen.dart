import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../utils/formatting.dart';
import '../widgets/status_pill.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final colors = context.colors;
    final query = state.search.trim().toLowerCase();
    final filtered = query.isEmpty
        ? state.products
        : state.products
            .where((p) =>
                p.name.toLowerCase().contains(query) ||
                p.category.toLowerCase().contains(query) ||
                p.sku.toLowerCase().contains(query))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth <= AppBreakpoints.compact;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => context.read<AppState>().setSearch(v),
                        decoration: InputDecoration(
                          hintText: compact ? 'Search…' : 'Search products…',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          filled: true,
                          fillColor: colors.bg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.field),
                            borderSide: BorderSide(color: colors.line),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => context.read<AppState>().startAddProduct(),
                      icon: const Icon(Icons.add, size: 17),
                      label: Text(compact ? 'Add' : 'Add Product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 15, vertical: compact ? 10 : 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${filtered.length} products', style: TextStyle(color: colors.muted, fontSize: 12.5)),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        if (filtered.isEmpty)
          _EmptyState(query: state.search)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = (constraints.maxWidth / 295).floor().clamp(1, 4);
              return Wrap(
                spacing: 15,
                runSpacing: 15,
                children: [
                  for (final p in filtered)
                    SizedBox(
                      width: (constraints.maxWidth - 15 * (columns - 1)) / columns,
                      child: _ProductCard(product: p),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = context.read<AppState>();
    final symbol = state.settings.currencySymbol;
    final margin = product.marginPercent;

    final (pillLabel, pillTone) = product.isOutOfStock
        ? ('Out of stock', PillTone.red)
        : product.isLowStock(state.settings.lowStockThreshold)
            ? ('Low stock', PillTone.amber)
            : ('In stock', PillTone.green);

    final initials = product.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(AppRadius.panel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: colors.greenSoft, borderRadius: BorderRadius.circular(AppRadius.tile)),
                child: Text(initials, style: TextStyle(color: colors.greenInk, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.ink)),
                    Text('${product.category} · ${product.sku}', style: TextStyle(fontSize: 11.5, color: colors.muted)),
                  ],
                ),
              ),
              StatusPill(label: pillLabel, tone: pillTone),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _Stat(label: 'Selling price', value: formatMoney(product.price, symbol, decimals: 2))),
              Expanded(child: _Stat(label: 'Unit cost', value: formatMoney(product.unitCost, symbol, decimals: 2), color: colors.amber)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _Stat(label: 'Profit/unit', value: formatMoney(product.profitPerUnit, symbol, decimals: 2), color: colors.greenInk)),
              Expanded(child: _Stat(label: 'Stock', value: '${product.stock} ${product.unit}')),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Container(height: 7, color: colors.hover),
                  Container(
                    height: 7,
                    width: constraints.maxWidth * (margin.clamp(0, 100) / 100),
                    color: colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => state.viewProduct(product.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.ink2,
                    side: BorderSide(color: colors.line),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                  ),
                  child: const Text('View', style: TextStyle(fontSize: 12.5)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => state.startEditProduct(product.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.ink2,
                    side: BorderSide(color: colors.line),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                  ),
                  child: const Text('Edit', style: TextStyle(fontSize: 12.5)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => state.confirm(
                    title: 'Delete ${product.name}?',
                    body: 'This removes the product permanently. Past sales stay in history.',
                    onConfirm: () {
                      state.deleteProduct(product.id);
                    },
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.red,
                    side: BorderSide(color: colors.line),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                  ),
                  child: const Text('Delete', style: TextStyle(fontSize: 12.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: colors.muted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: color ?? colors.ink)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        border: Border.all(color: colors.line, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(AppRadius.panel),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: colors.hover, borderRadius: BorderRadius.circular(AppRadius.tile)),
            child: Icon(Icons.inventory_2_outlined, color: colors.muted, size: 22),
          ),
          const SizedBox(height: 14),
          Text('No products match "$query"', style: TextStyle(fontWeight: FontWeight.w700, color: colors.ink, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Try a different search, or add a new product.', style: TextStyle(color: colors.muted, fontSize: 12.5)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<AppState>().startAddProduct(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
            ),
          ),
        ],
      ),
    );
  }
}
