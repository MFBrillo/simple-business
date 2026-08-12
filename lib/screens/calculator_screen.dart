import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../utils/formatting.dart';
import '../widgets/green_hero_panel.dart';
import '../widgets/section_card.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final name = TextEditingController();
  final price = TextEditingController();
  final material = TextEditingController();
  final packaging = TextEditingController();
  final labor = TextEditingController();
  final other = TextEditingController();
  final qty = TextEditingController(text: '1');
  double desiredMargin = 40;
  bool _marginInitialized = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [name, price, material, packaging, labor, other, qty]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [name, price, material, packaging, labor, other, qty]) {
      c.dispose();
    }
    super.dispose();
  }

  double _d(TextEditingController c) => double.tryParse(c.text) ?? 0;

  void _reset() {
    for (final c in [name, price, material, packaging, labor, other]) {
      c.clear();
    }
    qty.text = '1';
  }

  Future<void> _saveAsProduct(AppState state) async {
    if (saving) return;
    final trimmedName = name.text.trim();
    final priceValue = _d(price);
    if (trimmedName.isEmpty || priceValue <= 0) {
      state.showToast('Enter a product name and a price above ₱0');
      return;
    }
    // SKU is just a friendly placeholder — the real id is DB-assigned.
    final sku = 'CALC-${DateTime.now().millisecondsSinceEpoch % 100000}';
    setState(() => saving = true);
    final ok = await state.saveProduct(
      Product(
        id: 0,
        name: trimmedName,
        category: kProductCategories.first,
        sku: sku,
        price: priceValue,
        material: _d(material),
        packaging: _d(packaging),
        labor: _d(labor),
        other: _d(other),
        stock: 0,
        unit: kProductUnits.first,
      ),
      isNew: true,
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) state.showToast('$trimmedName saved as a product');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final colors = context.colors;
    final symbol = state.settings.currencySymbol;

    if (!_marginInitialized) {
      desiredMargin = state.settings.defaultMargin.clamp(5, 80);
      _marginInitialized = true;
    }

    final unitCost = _d(material) + _d(packaging) + _d(labor) + _d(other);
    final priceValue = _d(price);
    final quantity = double.tryParse(qty.text) ?? 0;
    final profitPerUnit = priceValue - unitCost;
    final margin = priceValue == 0 ? 0.0 : profitPerUnit / priceValue * 100;
    final revenue = priceValue * quantity;
    final totalCost = unitCost * quantity;
    final expectedProfit = revenue - totalCost;
    final recommendedPrice = desiredMargin >= 100 ? 0.0 : unitCost / (1 - desiredMargin / 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 680;
            final left = SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Field(label: 'Product name', child: _Input(controller: name, hint: 'e.g. Gulaman Jelly')),
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 13,
                    runSpacing: 13,
                    children: [
                      _FieldTile(width: 150, label: 'Selling price ₱', child: _Input(controller: price, isNumber: true)),
                      _FieldTile(width: 150, label: 'Material', child: _Input(controller: material, isNumber: true)),
                      _FieldTile(width: 150, label: 'Packaging', child: _Input(controller: packaging, isNumber: true)),
                      _FieldTile(width: 150, label: 'Labor', child: _Input(controller: labor, isNumber: true)),
                      _FieldTile(width: 150, label: 'Other', child: _Input(controller: other, isNumber: true)),
                      _FieldTile(width: 150, label: 'Quantity', child: _Input(controller: qty, isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton(
                        onPressed: saving ? null : () => _saveAsProduct(state),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.green,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: colors.hover,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                        ),
                        child: Text(saving ? 'Saving…' : 'Save as product'),
                      ),
                      OutlinedButton(
                        onPressed: saving ? null : _reset,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.ink2,
                          side: BorderSide(color: colors.line),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                        ),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            );

            final right = GreenHeroPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profit per unit', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    formatMoney(profitPerUnit, symbol, decimals: 2),
                    style: const TextStyle(color: Colors.white, fontSize: 46, fontWeight: FontWeight.w800, letterSpacing: -0.035),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      HeroPill(text: '${margin.toStringAsFixed(1)}% margin'),
                      HeroPill(text: '${formatMoney(unitCost, symbol, decimals: 2)} cost'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _HeroStat(label: 'Revenue × qty', value: formatMoney(revenue, symbol))),
                      Expanded(child: _HeroStat(label: 'Total cost', value: formatMoney(totalCost, symbol))),
                      Expanded(child: _HeroStat(label: 'Expected profit', value: formatMoney(expectedProfit, symbol))),
                    ],
                  ),
                ],
              ),
            );

            if (stacked) {
              return Column(children: [left, const SizedBox(height: 20), right]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: left), const SizedBox(width: 20), Expanded(child: right)],
            );
          },
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Desired margin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.ink2)),
                  Text('${desiredMargin.round()}%', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: colors.greenInk)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(activeTrackColor: colors.green, thumbColor: colors.green),
                child: Slider(
                  value: desiredMargin,
                  min: 5,
                  max: 80,
                  onChanged: (v) => setState(() => desiredMargin = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('5%', style: TextStyle(fontSize: 11, color: colors.muted)),
                    Text('40%', style: TextStyle(fontSize: 11, color: colors.muted)),
                    Text('80%', style: TextStyle(fontSize: 11, color: colors.muted)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: colors.greenSoft, borderRadius: BorderRadius.circular(AppRadius.tileLg)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recommended selling price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.greenInk)),
                    const SizedBox(height: 4),
                    Text(
                      formatMoney(recommendedPrice, symbol, decimals: 2),
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: colors.greenInk, letterSpacing: -0.02),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'At ${desiredMargin.round()}% margin on ${formatMoney(unitCost, symbol, decimals: 2)} unit cost.',
                      style: TextStyle(fontSize: 12.5, color: colors.ink2),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => setState(() => price.text = recommendedPrice.toStringAsFixed(2)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.greenInk,
                        side: BorderSide(color: colors.green),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                      ),
                      child: const Text('Use this price above'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
      ],
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

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final bool isNumber;
  const _Input({required this.controller, this.hint, this.isNumber = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: TextStyle(fontSize: 13.5, color: colors.ink),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: colors.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field), borderSide: BorderSide(color: colors.line)),
      ),
    );
  }
}
