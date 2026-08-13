import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/product_material.dart';
import '../state/app_screen.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../utils/formatting.dart';
import '../widgets/green_hero_panel.dart';
import '../widgets/section_card.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

/// One editable ingredient row — name/cost/quantity controllers, freed via
/// [dispose]. Kept as plain objects (not widgets) so the row list can be
/// mutated with ordinary `List` operations from [_ProductFormScreenState].
class _MaterialRow {
  final TextEditingController name;
  final TextEditingController cost;
  final TextEditingController qty;

  _MaterialRow({String name = '', String cost = '', String qty = ''})
      : name = TextEditingController(text: name),
        cost = TextEditingController(text: cost),
        qty = TextEditingController(text: qty);

  double get _costValue => double.tryParse(cost.text) ?? 0;
  double get _qtyValue => double.tryParse(qty.text) ?? 0;
  double get subtotal => _costValue * _qtyValue;

  void dispose() {
    name.dispose();
    cost.dispose();
    qty.dispose();
  }
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  late final TextEditingController name;
  late final TextEditingController sku;
  late final TextEditingController price;
  late final TextEditingController material;
  late final TextEditingController packaging;
  late final TextEditingController labor;
  late final TextEditingController other;
  late final TextEditingController stock;
  late final TextEditingController batchYield;
  late List<_MaterialRow> materialRows;
  late String category;
  late String unit;
  int? editingId;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    editingId = state.editingId;
    final existing = editingId == null ? null : state.productById(editingId!);

    name = TextEditingController(text: existing?.name ?? '');
    sku = TextEditingController(text: existing?.sku ?? '');
    price = TextEditingController(text: _fmt(existing?.price));
    material = TextEditingController(text: _fmt(existing?.material));
    packaging = TextEditingController(text: _fmt(existing?.packaging));
    labor = TextEditingController(text: _fmt(existing?.labor));
    other = TextEditingController(text: _fmt(existing?.other));
    stock = TextEditingController(text: existing?.stock.toString() ?? '');
    category = existing?.category ?? kProductCategories.first;
    unit = existing?.unit ?? kProductUnits.first;

    final existingMaterials = existing?.materials ?? const <ProductMaterial>[];
    materialRows = [
      for (final m in existingMaterials) _MaterialRow(name: m.name, cost: _fmt(m.unitCost), qty: _fmt(m.quantity)),
    ];
    batchYield = TextEditingController(text: existingMaterials.isEmpty ? '' : existing!.batchYield.toString());
    for (final row in materialRows) {
      row.name.addListener(() => setState(() {}));
      row.cost.addListener(_onMaterialsChanged);
      row.qty.addListener(_onMaterialsChanged);
    }
    batchYield.addListener(_onMaterialsChanged);

    for (final c in [name, sku, price, material, packaging, labor, other, stock]) {
      c.addListener(() => setState(() {}));
    }
  }

  static String _fmt(double? v) => v == null ? '' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString());

  @override
  void dispose() {
    for (final c in [name, sku, price, material, packaging, labor, other, stock, batchYield]) {
      c.dispose();
    }
    for (final row in materialRows) {
      row.dispose();
    }
    super.dispose();
  }

  double _d(TextEditingController c) => double.tryParse(c.text) ?? 0;
  int _i(TextEditingController c) => int.tryParse(c.text) ?? 0;

  /// Keeps [material] in sync with the ingredient rows while any exist —
  /// `total ÷ finished quantity`. Once the last row is removed this stops
  /// touching [material], leaving it as a normal, directly-editable field
  /// seeded with whatever it last computed to.
  void _onMaterialsChanged() {
    if (materialRows.isEmpty) {
      setState(() {});
      return;
    }
    final total = materialRows.fold(0.0, (sum, r) => sum + r.subtotal);
    final yieldQty = int.tryParse(batchYield.text) ?? 0;
    final perUnit = yieldQty > 0 ? total / yieldQty : 0.0;
    material.text = perUnit.toStringAsFixed(2);
  }

  void _addMaterialRow() {
    final row = _MaterialRow();
    row.name.addListener(() => setState(() {}));
    row.cost.addListener(_onMaterialsChanged);
    row.qty.addListener(_onMaterialsChanged);
    setState(() => materialRows.add(row));
  }

  void _removeMaterialRow(_MaterialRow row) {
    setState(() => materialRows.remove(row));
    row.dispose();
    _onMaterialsChanged();
  }

  Future<void> _save() async {
    if (saving) return;
    final state = context.read<AppState>();
    final trimmedName = name.text.trim();
    final priceValue = _d(price);
    if (trimmedName.isEmpty || priceValue <= 0) {
      state.showToast('Enter a product name and a price above ₱0');
      return;
    }
    final isNew = editingId == null;
    final materialsList = [
      for (final row in materialRows)
        if (row.name.text.trim().isNotEmpty || row._costValue != 0 || row._qtyValue != 0)
          ProductMaterial(name: row.name.text.trim(), unitCost: row._costValue, quantity: row._qtyValue),
    ];
    // id is DB-assigned on insert; 0 is just a placeholder for the isNew case.
    final product = Product(
      id: isNew ? 0 : editingId!,
      name: trimmedName,
      category: category,
      sku: sku.text.trim(),
      price: priceValue,
      material: _d(material),
      packaging: _d(packaging),
      labor: _d(labor),
      other: _d(other),
      stock: _i(stock),
      unit: unit,
      materials: materialsList,
      batchYield: materialsList.isEmpty ? 1 : (int.tryParse(batchYield.text) ?? 1),
    );

    setState(() => saving = true);
    final ok = await state.saveProduct(product, isNew: isNew);
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) {
      state.goTo(AppScreen.products);
      state.showToast(isNew ? 'Product added' : 'Changes saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = editingId == null;
    final unitCost = _d(material) + _d(packaging) + _d(labor) + _d(other);
    final priceValue = _d(price);
    final profitPerUnit = priceValue - unitCost;
    final margin = priceValue == 0 ? 0.0 : profitPerUnit / priceValue * 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 680;
        final form = _FormCard(
          isNew: isNew,
          name: name,
          sku: sku,
          price: price,
          material: material,
          packaging: packaging,
          labor: labor,
          other: other,
          stock: stock,
          batchYield: batchYield,
          materialRows: materialRows,
          onAddMaterialRow: _addMaterialRow,
          onRemoveMaterialRow: _removeMaterialRow,
          category: category,
          unit: unit,
          onCategoryChanged: (v) => setState(() => category = v),
          onUnitChanged: (v) => setState(() => unit = v),
          onSave: _save,
          saving: saving,
        );
        final summary = _SummaryCard(unitCost: unitCost, price: priceValue, profitPerUnit: profitPerUnit, margin: margin);

        if (stacked) {
          return Column(children: [form, const SizedBox(height: 20), summary]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: form),
            const SizedBox(width: 20),
            Expanded(child: summary),
          ],
        );
      },
    );
  }
}

class _FormCard extends StatelessWidget {
  final bool isNew;
  final bool saving;
  final TextEditingController name, sku, price, material, packaging, labor, other, stock, batchYield;
  final List<_MaterialRow> materialRows;
  final VoidCallback onAddMaterialRow;
  final ValueChanged<_MaterialRow> onRemoveMaterialRow;
  final String category, unit;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onUnitChanged;
  final VoidCallback onSave;

  const _FormCard({
    required this.isNew,
    required this.saving,
    required this.name,
    required this.sku,
    required this.price,
    required this.material,
    required this.packaging,
    required this.labor,
    required this.other,
    required this.stock,
    required this.batchYield,
    required this.materialRows,
    required this.onAddMaterialRow,
    required this.onRemoveMaterialRow,
    required this.category,
    required this.unit,
    required this.onCategoryChanged,
    required this.onUnitChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(label: 'Product name', child: _TextInput(controller: name, hint: 'e.g. Gulaman Jelly')),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _Field(
                  label: 'Category',
                  child: _Select(value: category, items: kProductCategories, onChanged: onCategoryChanged),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(child: _Field(label: 'SKU', child: _TextInput(controller: sku, hint: 'e.g. GUL-001'))),
            ],
          ),
          const SizedBox(height: 13),
          _Field(label: 'Selling price ₱', child: _TextInput(controller: price, isNumber: true)),
          const SizedBox(height: 18),
          Divider(color: colors.line),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('Ingredients (optional)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: colors.ink2)),
              ),
              TextButton.icon(
                onPressed: onAddMaterialRow,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add ingredient', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(
                  foregroundColor: colors.greenInk,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'List what one batch uses — material cost per unit below is worked out for you.',
            style: TextStyle(fontSize: 11.5, color: colors.muted),
          ),
          if (materialRows.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final row in materialRows) ...[
              _MaterialRowFields(row: row, onRemove: () => onRemoveMaterialRow(row)),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            _FieldTile(width: 170, label: 'Finished quantity', child: _TextInput(controller: batchYield, isNumber: true, hint: 'e.g. 30')),
            const SizedBox(height: 12),
            _IngredientsSummary(materialRows: materialRows, batchYield: batchYield),
          ],
          const SizedBox(height: 18),
          Divider(color: colors.line),
          const SizedBox(height: 8),
          Text('Cost breakdown — per unit', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: colors.ink2)),
          const SizedBox(height: 13),
          Wrap(
            spacing: 13,
            runSpacing: 13,
            children: [
              _FieldTile(
                width: 150,
                label: materialRows.isEmpty ? 'Material' : 'Material (auto)',
                child: _TextInput(controller: material, isNumber: true, enabled: materialRows.isEmpty),
              ),
              _FieldTile(width: 150, label: 'Packaging', child: _TextInput(controller: packaging, isNumber: true)),
              _FieldTile(width: 150, label: 'Labor', child: _TextInput(controller: labor, isNumber: true)),
              _FieldTile(width: 150, label: 'Other', child: _TextInput(controller: other, isNumber: true)),
              _FieldTile(width: 150, label: 'Initial stock', child: _TextInput(controller: stock, isNumber: true)),
              _FieldTile(width: 150, label: 'Unit', child: _Select(value: unit, items: kProductUnits, onChanged: onUnitChanged)),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton(
                onPressed: saving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: colors.hover,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                ),
                child: Text(saving ? 'Saving…' : (isNew ? 'Save product' : 'Save changes')),
              ),
              OutlinedButton(
                onPressed: saving ? null : () => context.read<AppState>().goTo(AppScreen.products),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.ink2,
                  side: BorderSide(color: colors.line),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double unitCost, price, profitPerUnit, margin;
  const _SummaryCard({required this.unitCost, required this.price, required this.profitPerUnit, required this.margin});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final symbol = state.settings.currencySymbol;
    final verdict = margin >= 40
        ? 'Healthy margin'
        : margin >= 20
            ? 'Thin — consider raising price'
            : profitPerUnit < 0
                ? 'Losing money per unit'
                : 'Very thin margin';

    return GreenHeroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profit per unit', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            formatMoney(profitPerUnit, symbol, decimals: 2),
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -0.02),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              HeroPill(text: '${margin.toStringAsFixed(1)}% margin'),
              HeroPill(text: '${formatMoney(unitCost, symbol, decimals: 2)} cost'),
            ],
          ),
          const SizedBox(height: 8),
          Text(verdict, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          _Row('Selling price', formatMoney(price, symbol, decimals: 2)),
          _Row('Total unit cost', formatMoney(unitCost, symbol, decimals: 2)),
          _Row('Profit per unit', formatMoney(profitPerUnit, symbol, decimals: 2)),
          _Row('Profit margin', '${margin.toStringAsFixed(1)}%'),
          _Row('Break-even price', formatMoney(unitCost, symbol, decimals: 2)),
          const SizedBox(height: 12),
          const Text(
            'unitCost = material + packaging + labor + other · margin = profit ÷ price × 100',
            style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
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

class _FieldTile extends StatelessWidget {
  final double width;
  final String label;
  final Widget child;
  const _FieldTile({required this.width, required this.label, required this.child});

  @override
  Widget build(BuildContext context) => SizedBox(width: width, child: _Field(label: label, child: child));
}

/// One "Sugar · ₱25 · ×1" ingredient row: name, unit cost, quantity, a live
/// subtotal, and a remove button. Rebuilds via the row's own controller
/// listeners (added in [_ProductFormScreenState]), same pattern as the rest
/// of the form.
class _MaterialRowFields extends StatelessWidget {
  final _MaterialRow row;
  final VoidCallback onRemove;
  const _MaterialRowFields({required this.row, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: _TextInput(controller: row.name, hint: 'e.g. Sugar'),
        ),
        const SizedBox(width: 6),
        SizedBox(width: 64, child: _TextInput(controller: row.cost, hint: '₱', isNumber: true)),
        const SizedBox(width: 6),
        SizedBox(width: 52, child: _TextInput(controller: row.qty, hint: '×qty', isNumber: true)),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text(
            row.subtotal == 0 ? '—' : formatMoney(row.subtotal, '₱', decimals: 2),
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: colors.ink2),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: onRemove,
          icon: Icon(Icons.close_rounded, size: 17, color: colors.muted),
          tooltip: 'Remove ingredient',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ],
    );
  }
}

/// Total ingredient cost, finished quantity, and the resulting per-unit
/// material cost — the number that actually feeds [Product.material].
class _IngredientsSummary extends StatelessWidget {
  final List<_MaterialRow> materialRows;
  final TextEditingController batchYield;
  const _IngredientsSummary({required this.materialRows, required this.batchYield});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = materialRows.fold(0.0, (sum, r) => sum + r.subtotal);
    final yieldQty = int.tryParse(batchYield.text) ?? 0;
    final perUnit = yieldQty > 0 ? total / yieldQty : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: colors.hover, borderRadius: BorderRadius.circular(AppRadius.field)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryLine('Total material cost', formatMoney(total, '₱', decimals: 2), colors),
          _SummaryLine(
            'Material cost / unit',
            yieldQty > 0 ? formatMoney(perUnit, '₱', decimals: 2) : 'Enter finished quantity',
            colors,
            emphasize: yieldQty > 0,
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;
  final bool emphasize;
  const _SummaryLine(this.label, this.value, this.colors, {this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: colors.muted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: emphasize ? colors.greenInk : colors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final bool isNumber;
  final bool enabled;
  const _TextInput({required this.controller, this.hint, this.isNumber = false, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: TextStyle(fontSize: 13.5, color: colors.ink),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: enabled ? colors.bg : colors.hover,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: colors.green, width: 1.5),
        ),
      ),
    );
  }
}

class _Select extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  const _Select({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      style: TextStyle(fontSize: 13.5, color: colors.ink),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: colors.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: colors.line),
        ),
      ),
      items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
