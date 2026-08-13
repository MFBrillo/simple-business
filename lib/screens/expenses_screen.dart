import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../models/supply.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../utils/formatting.dart';
import '../widgets/kpi_card.dart';
import '../widgets/section_card.dart';
import '../widgets/status_pill.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final desc = TextEditingController();
  final amount = TextEditingController();
  final notes = TextEditingController();
  final quantity = TextEditingController();
  String category = kExpenseCategories.first;
  DateTime date = DateTime.now();
  bool saving = false;

  @override
  void dispose() {
    desc.dispose();
    amount.dispose();
    notes.dispose();
    quantity.dispose();
    super.dispose();
  }

  Future<void> _add(AppState state) async {
    if (saving) return;
    final d = desc.text.trim();
    final a = double.tryParse(amount.text) ?? 0;
    if (d.isEmpty || a <= 0) {
      state.showToast('Enter a description and an amount above ₱0');
      return;
    }
    final q = int.tryParse(quantity.text);
    setState(() => saving = true);
    // id is DB-assigned; 0 is just a placeholder for the insert payload.
    final ok = await state.addExpense(Expense(
      id: 0,
      description: d,
      category: category,
      amount: a,
      date: date,
      notes: notes.text.trim(),
      quantity: q != null && q > 0 ? q : null,
    ));
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) {
      desc.clear();
      amount.clear();
      notes.clear();
      quantity.clear();
      setState(() => date = DateTime.now());
      state.showToast('Expense added');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final colors = context.colors;
    final symbol = state.settings.currencySymbol;

    final byCategory = <String, double>{};
    for (final e in state.expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }
    final sortedCategories = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final largest = sortedCategories.isEmpty ? null : sortedCategories.first;
    final categoryColors = [colors.amber, colors.red, colors.bar];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KpiGrid(cards: [
          KpiCard(label: "Today's expenses", value: formatMoney(state.todayExpensesTotal, symbol), valueColor: colors.red),
          KpiCard(label: "This month's expenses", value: formatMoney(state.monthExpensesTotal, symbol), valueColor: colors.red),
          KpiCard(
            label: 'Largest category',
            value: largest?.key ?? '—',
            note: largest == null ? null : formatMoney(largest.value, symbol),
            valueColor: colors.amber,
          ),
        ]),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Add expense'),
              const SizedBox(height: 16),
              _Field(label: 'Description', child: _TextInput(controller: desc, hint: 'e.g. Tricycle fare')),
              const SizedBox(height: 13),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoCol = constraints.maxWidth > 480;
                  final fields = [
                    _Field(
                      label: 'Category',
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        isExpanded: true,
                        decoration: _decoration(colors),
                        items: [for (final c in kExpenseCategories) DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))],
                        onChanged: (v) => setState(() => category = v ?? category),
                      ),
                    ),
                    _Field(label: 'Amount ₱', child: _TextInput(controller: amount, isNumber: true)),
                    _Field(
                      label: 'Restocks (pc, optional)',
                      child: _TextInput(controller: quantity, isNumber: true, hint: 'e.g. 100'),
                    ),
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
                          decoration: _decoration(colors),
                          child: Text(
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 13.5, color: colors.ink),
                          ),
                        ),
                      ),
                    ),
                    _Field(label: 'Notes', child: _TextInput(controller: notes, hint: 'Optional')),
                  ];
                  if (twoCol) {
                    return Wrap(
                      spacing: 13,
                      runSpacing: 13,
                      children: [for (final f in fields) SizedBox(width: (constraints.maxWidth - 13) / 2, child: f)],
                    );
                  }
                  return Column(children: [for (final f in fields) Padding(padding: const EdgeInsets.only(bottom: 13), child: f)]);
                },
              ),
              const SizedBox(height: 6),
              Text(
                "If this expense is restocking a supply (cups, spoons…), set Restocks and the Description becomes that supply's name — its running count goes up by that many, then down by 1 on every sale.",
                style: TextStyle(fontSize: 11.5, color: colors.muted, height: 1.4),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : () => _add(state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: colors.hover,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                  ),
                  child: Text(saving ? 'Adding…' : 'Add expense', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Supplies on hand'),
              const SizedBox(height: 14),
              if (state.supplies.isEmpty)
                Text(
                  'No tracked supplies yet — add an expense above with a Restocks quantity to start one.',
                  style: TextStyle(color: colors.muted, fontSize: 13),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [for (final s in state.supplies) _SupplyPill(supply: s, threshold: state.settings.lowStockThreshold)],
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Spending by category'),
              const SizedBox(height: 16),
              if (sortedCategories.isEmpty)
                Text('No expenses logged yet.', style: TextStyle(color: colors.muted, fontSize: 13))
              else
                for (var i = 0; i < sortedCategories.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(sortedCategories[i].key, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colors.ink2)),
                            Text(formatMoney(sortedCategories[i].value, symbol), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: colors.ink)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LayoutBuilder(
                            builder: (context, constraints) => Stack(
                              children: [
                                Container(height: 8, color: colors.hover),
                                Container(
                                  height: 8,
                                  width: constraints.maxWidth * (sortedCategories[i].value / (largest!.value)).clamp(0, 1),
                                  color: categoryColors[i % categoryColors.length],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Expense log'),
              const SizedBox(height: 14),
              if (state.expenses.isEmpty)
                Text('No expenses logged yet.', style: TextStyle(color: colors.muted, fontSize: 13))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 560),
                    child: Column(
                      children: [for (final e in state.expenses) _ExpenseRow(expense: e, symbol: symbol)],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration(AppColors colors) => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: colors.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field), borderSide: BorderSide(color: colors.line)),
      );
}

/// "Plastic Cup — 97 pc" chip; ambers out under the same low-stock
/// threshold Products use, reds out at zero.
class _SupplyPill extends StatelessWidget {
  final Supply supply;
  final int threshold;
  const _SupplyPill({required this.supply, required this.threshold});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, fg) = supply.quantity <= 0
        ? (colors.redSoft, colors.red)
        : supply.quantity <= threshold
            ? (colors.amberSoft, colors.amber)
            : (colors.hover, colors.ink2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.field)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(supply.name, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg)),
          const SizedBox(width: 6),
          Text('${supply.quantity} pc', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: fg)),
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

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final bool isNumber;
  const _TextInput({required this.controller, this.hint, this.isNumber = false});

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

class _ExpenseRow extends StatelessWidget {
  final Expense expense;
  final String symbol;
  const _ExpenseRow({required this.expense, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = context.read<AppState>();
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.line))),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}-${expense.date.day.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12.5, color: colors.ink2),
            ),
          ),
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        expense.description,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.ink),
                      ),
                    ),
                    if (expense.quantity != null && expense.quantity! > 0) ...[
                      const SizedBox(width: 6),
                      Text('+${expense.quantity} pc', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.greenInk)),
                    ],
                  ],
                ),
                if (expense.notes.isNotEmpty)
                  Text(expense.notes, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: colors.muted)),
              ],
            ),
          ),
          SizedBox(width: 130, child: StatusPill(label: expense.category, tone: PillTone.red)),
          SizedBox(
            width: 90,
            child: Text(formatMoney(expense.amount, symbol), textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.red)),
          ),
          SizedBox(
            width: 44,
            child: IconButton(
              onPressed: () => state.confirm(
                title: 'Delete this expense?',
                body: 'This removes "${expense.description}" permanently.',
                onConfirm: () {
                  state.deleteExpense(expense.id);
                },
              ),
              icon: Icon(Icons.delete_outline, size: 18, color: colors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
