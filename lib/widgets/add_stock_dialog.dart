import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';

/// "Add stock" modal: overlay `rgba(10,16,14,.45)`, sheet radius 20
/// padding 24 max-width 390, title + "Product — currently N unit",
/// quantity field, Cancel / green Add stock. Shared by Product Details
/// and Inventory.
Future<void> showAddStockDialog(BuildContext context, Product product) {
  return showDialog(
    context: context,
    barrierColor: const Color(0x730A100E),
    builder: (context) => _AddStockDialog(product: product),
  );
}

class _AddStockDialog extends StatefulWidget {
  final Product product;
  const _AddStockDialog({required this.product});

  @override
  State<_AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<_AddStockDialog> {
  final qty = TextEditingController(text: '1');
  bool saving = false;

  @override
  void dispose() {
    qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = context.watch<AppState>();
    // Re-fetch in case stock changed since the dialog opened.
    final product = state.productById(widget.product.id) ?? widget.product;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 390),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(AppRadius.modal)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add stock', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.ink)),
            const SizedBox(height: 4),
            Text(
              '${product.name} — currently ${product.stock} ${product.unit}',
              style: TextStyle(fontSize: 12.5, color: colors.muted),
            ),
            const SizedBox(height: 16),
            Text('Quantity to add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.ink2)),
            const SizedBox(height: 6),
            TextField(
              controller: qty,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: colors.bg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field), borderSide: BorderSide(color: colors.line)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.ink,
                      side: BorderSide(color: colors.line),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final addQty = int.tryParse(qty.text) ?? 0;
                            if (addQty <= 0) {
                              state.showToast('Enter a quantity above 0');
                              return;
                            }
                            setState(() => saving = true);
                            final ok = await state.saveProduct(product.copyWith(stock: product.stock + addQty), isNew: false);
                            if (!context.mounted) return;
                            if (ok) {
                              state.showToast('Added $addQty ${product.unit} to ${product.name}');
                              Navigator.of(context).pop();
                            } else {
                              setState(() => saving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: colors.hover,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                    ),
                    child: Text(saving ? 'Adding…' : 'Add stock'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
