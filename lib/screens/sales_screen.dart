import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/sale.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../utils/formatting.dart';
import '../widgets/section_card.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  int? productId;
  final qty = TextEditingController(text: '1');
  final price = TextEditingController();
  String method = kPaymentMethods.first;
  DateTime date = DateTime.now();
  bool saving = false;

  /// Non-null while the "Record a sale" form is instead editing this
  /// existing sale's id (see [_startEditSale]).
  int? editingSaleId;

  @override
  void initState() {
    super.initState();
    qty.addListener(() => setState(() {}));
    price.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    qty.dispose();
    price.dispose();
    super.dispose();
  }

  void _selectProduct(Product p) {
    setState(() {
      productId = p.id;
      price.text = p.price == p.price.roundToDouble() ? p.price.toStringAsFixed(0) : p.price.toString();
    });
  }

  void _startEditSale(Sale s) {
    setState(() {
      editingSaleId = s.id;
      productId = s.productId;
      qty.text = '${s.qty}';
      price.text = s.price == s.price.roundToDouble() ? s.price.toStringAsFixed(0) : s.price.toString();
      method = s.method;
      date = s.date;
    });
  }

  void _resetForm() {
    setState(() {
      editingSaleId = null;
      productId = null;
      qty.text = '1';
      price.clear();
      method = kPaymentMethods.first;
      date = DateTime.now();
    });
  }

  Future<void> _record(AppState state, Product product) async {
    if (saving) return;
    final q = int.tryParse(qty.text) ?? 0;
    final p = double.tryParse(price.text) ?? 0;
    if (q <= 0) {
      state.showToast('Enter a quantity above 0');
      return;
    }
    final isNew = editingSaleId == null;
    setState(() => saving = true);
    double? profit;
    bool ok;
    if (isNew) {
      profit = await state.recordSale(productId: product.id, qty: q, price: p, method: method, date: date);
      ok = profit != null;
    } else {
      ok = await state.updateSale(
        Sale(id: editingSaleId!, productId: product.id, qty: q, price: p, method: method, date: date),
      );
      profit = (p - product.unitCost) * q;
    }
    if (!mounted) return;
    setState(() => saving = false);
    if (!ok) return;
    if (isNew) {
      // Keep productId/price/method as-is (selling the same product again
      // is common) — only the qty/date reset between sales.
      setState(() {
        qty.text = '1';
        date = DateTime.now();
      });
      state.showToast('Sale recorded — ${formatMoney(profit!, state.settings.currencySymbol)} profit earned');
    } else {
      _resetForm();
      state.showToast('Sale updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final colors = context.colors;
    final symbol = state.settings.currencySymbol;
    final product = productId == null ? null : state.productById(productId!);

    final q = int.tryParse(qty.text) ?? 0;
    final p = double.tryParse(price.text) ?? 0;
    final revenue = p * q;
    final unitCost = product?.unitCost ?? 0;
    final cost = unitCost * q;
    final profit = revenue - cost;
    final margin = revenue == 0 ? 0.0 : profit / revenue * 100;
    final stockAfter = product == null ? 0 : product.stock - q;
    final oversell = product != null && q > product.stock;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 680;
        final form = SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(title: editingSaleId == null ? 'Record a sale' : 'Edit sale'),
              const SizedBox(height: 16),
              Text('Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.ink2)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                // FormField only reads `initialValue` on first build (or on
                // an explicit reset) — without this key, _startEditSale /
                // _resetForm setting productId programmatically wouldn't be
                // reflected here, only picking a product via onChanged
                // would.
                key: ValueKey('sale-product-$editingSaleId'),
                initialValue: productId,
                isExpanded: true,
                hint: const Text('Select a product'),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: colors.bg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field), borderSide: BorderSide(color: colors.line)),
                ),
                items: [
                  // Archived (soft-deleted) products stay out of the picker
                  // — see AppState.deleteProduct.
                  for (final p in state.products.where((p) => !p.archived))
                    DropdownMenuItem(
                      value: p.id,
                      child: Text('${p.name} · ${formatMoney(p.price, symbol, decimals: 2)} · ${p.stock} ${p.unit}'),
                    ),
                ],
                onChanged: (id) {
                  final p = state.products.where((x) => x.id == id).firstOrNull;
                  if (p != null) _selectProduct(p);
                },
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      label: 'Quantity',
                      child: TextField(
                        controller: qty,
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        decoration: _inputDecoration(colors),
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: _Field(
                      label: 'Selling price ₱',
                      child: TextField(
                        controller: price,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration(colors),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              _Field(
                label: 'Date',
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => date = picked);
                  },
                  child: InputDecorator(
                    decoration: _inputDecoration(colors),
                    child: Text(
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 13.5, color: colors.ink),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 13),
              Text('Payment method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.ink2)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in kPaymentMethods)
                    _MethodPill(label: m, selected: m == method, onTap: () => setState(() => method = m)),
                ],
              ),
              if (oversell || (product?.isOutOfStock ?? false)) ...[
                const SizedBox(height: 13),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: colors.amberSoft, borderRadius: BorderRadius.circular(AppRadius.field)),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          product!.isOutOfStock
                              ? '${product.name} is out of stock.'
                              : 'Only ${product.stock} ${product.unit} left in stock — this sale would oversell.',
                          style: TextStyle(fontSize: 12.5, color: colors.ink2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (editingSaleId != null) ...[
                const SizedBox(height: 13),
                Text(
                  "Editing doesn't adjust stock automatically — adjust it separately if needed.",
                  style: TextStyle(fontSize: 11.5, color: colors.muted, height: 1.4),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (product == null || saving) ? null : () => _record(state, product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: colors.hover,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                      ),
                      child: Text(
                        saving
                            ? (editingSaleId == null ? 'Recording…' : 'Saving…')
                            : (editingSaleId == null ? 'Record sale · ${formatMoney(revenue, symbol)}' : 'Save changes'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (editingSaleId != null) ...[
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: saving ? null : _resetForm,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.ink2,
                        side: BorderSide(color: colors.line),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );

        final summary = SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Sale summary'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _SummaryTile(label: 'Quantity', value: '$q')),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryTile(label: 'Unit price', value: formatMoney(p, symbol, decimals: 2))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _SummaryTile(label: 'Sales', value: formatMoney(revenue, symbol))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryTile(label: 'Profit', value: formatMoney(profit, symbol), highlight: true),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: colors.line),
              const SizedBox(height: 10),
              _FormulaRow('Revenue = price × qty', formatMoney(revenue, symbol)),
              _FormulaRow('Cost = unit cost × qty', formatMoney(cost, symbol)),
              _FormulaRow('Margin', '${margin.toStringAsFixed(1)}%'),
              _FormulaRow('Stock after sale', product == null ? '—' : '$stockAfter ${product.unit}'),
            ],
          ),
        );

        final layout = stacked
            ? Column(children: [form, const SizedBox(height: 20), summary])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: form), const SizedBox(width: 20), Expanded(child: summary)],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            layout,
            const SizedBox(height: 20),
            _SalesHistoryCard(symbol: symbol, onEdit: _startEditSale),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(AppColors colors) => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: colors.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field), borderSide: BorderSide(color: colors.line)),
      );
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.ink2)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _MethodPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MethodPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? colors.greenSoft : colors.bg,
          border: Border.all(color: selected ? colors.green : colors.line),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? colors.greenInk : colors.ink2,
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _SummaryTile({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? colors.greenSoft : colors.bg,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: colors.muted)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: highlight ? colors.greenInk : colors.ink)),
        ],
      ),
    );
  }
}

class _FormulaRow extends StatelessWidget {
  final String label;
  final String value;
  const _FormulaRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12.5, color: colors.muted), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.ink2)),
        ],
      ),
    );
  }
}

class _SalesHistoryCard extends StatelessWidget {
  final String symbol;
  final ValueChanged<Sale> onEdit;
  const _SalesHistoryCard({required this.symbol, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = context.watch<AppState>();
    final sales = state.sales;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Sales history'),
          const SizedBox(height: 14),
          if (sales.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('No sales recorded yet.', style: TextStyle(color: colors.muted, fontSize: 13)),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 720),
                child: Column(
                  children: [
                    _HistoryHeader(colors: colors),
                    for (final s in sales) _HistoryRow(sale: s, symbol: symbol, onEdit: onEdit),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final AppColors colors;
  const _HistoryHeader({required this.colors});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: colors.muted, letterSpacing: 0.05);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text('DATE', style: style)),
          SizedBox(width: 200, child: Text('PRODUCT', style: style)),
          SizedBox(width: 60, child: Text('QTY', style: style, textAlign: TextAlign.right)),
          SizedBox(width: 90, child: Text('SALES', style: style, textAlign: TextAlign.right)),
          SizedBox(width: 90, child: Text('COST', style: style, textAlign: TextAlign.right)),
          SizedBox(width: 90, child: Text('PROFIT', style: style, textAlign: TextAlign.right)),
          SizedBox(width: 110, child: Text('PAYMENT', style: style)),
          const SizedBox(width: 44),
          const SizedBox(width: 80),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final Sale sale;
  final String symbol;
  final ValueChanged<Sale> onEdit;
  const _HistoryRow({required this.sale, required this.symbol, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = context.read<AppState>();
    final product = state.productById(sale.productId);
    final cost = (product?.unitCost ?? 0) * sale.qty;
    final profit = sale.revenue - cost;

    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.line))),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(formatDateLabel(sale.date), style: TextStyle(fontSize: 12.5, color: colors.ink2))),
          SizedBox(
            width: 200,
            child: Text(product?.name ?? '—', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.ink)),
          ),
          SizedBox(width: 60, child: Text('${sale.qty}', textAlign: TextAlign.right, style: TextStyle(fontSize: 12.5, color: colors.ink2))),
          SizedBox(width: 90, child: Text(formatMoney(sale.revenue, symbol), textAlign: TextAlign.right, style: TextStyle(fontSize: 12.5, color: colors.ink2))),
          SizedBox(width: 90, child: Text(formatMoney(cost, symbol), textAlign: TextAlign.right, style: TextStyle(fontSize: 12.5, color: colors.amber))),
          SizedBox(
            width: 90,
            child: Text(formatMoney(profit, symbol), textAlign: TextAlign.right, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: colors.greenInk)),
          ),
          SizedBox(
            width: 110,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: colors.hover, borderRadius: BorderRadius.circular(99)),
              child: Text(sale.method, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.ink2)),
            ),
          ),
          SizedBox(
            width: 44,
            child: IconButton(
              onPressed: () => onEdit(sale),
              icon: Icon(Icons.edit_outlined, size: 18, color: colors.muted),
              tooltip: 'Edit sale',
            ),
          ),
          SizedBox(
            width: 80,
            child: OutlinedButton(
              onPressed: () => state.confirm(
                title: 'Void this sale?',
                body: 'Stock will not be restored automatically — adjust it separately if needed.',
                onConfirm: () {
                  state.voidSale(sale.id);
                },
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.red,
                side: BorderSide(color: colors.line),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
              ),
              child: const Text('Void', style: TextStyle(fontSize: 11.5)),
            ),
          ),
        ],
      ),
    );
  }
}
