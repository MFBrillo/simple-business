import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/sale.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/section_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController businessName;
  late final TextEditingController lowStock;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppState>().settings;
    businessName = TextEditingController(text: settings.businessName);
    lowStock = TextEditingController(text: settings.lowStockThreshold.toString());
  }

  @override
  void dispose() {
    businessName.dispose();
    lowStock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final colors = context.colors;
    final settings = state.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Business profile'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: colors.greenSoft, borderRadius: BorderRadius.circular(AppRadius.tile)),
                    child: Text('₱', style: TextStyle(color: colors.greenInk, fontWeight: FontWeight.w800, fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  OutlinedButton(
                    onPressed: () => state.showToast('Logo upload coming soon'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.ink2,
                      side: BorderSide(color: colors.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                    ),
                    child: const Text('Upload logo'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _Field(
                label: 'Business name',
                child: TextField(
                  controller: businessName,
                  decoration: _decoration(colors),
                  style: TextStyle(fontSize: 13.5, color: colors.ink),
                  onChanged: (v) => state.updateSettings(settings.copyWith(businessName: v)),
                ),
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 13,
                runSpacing: 13,
                children: [
                  SizedBox(
                    width: 200,
                    child: _Field(
                      label: 'Currency',
                      child: DropdownButtonFormField<String>(
                        initialValue: settings.currencyCode,
                        isExpanded: true,
                        decoration: _decoration(colors),
                        items: const [
                          DropdownMenuItem(value: 'PHP', child: Text('₱ PHP')),
                          DropdownMenuItem(value: 'USD', child: Text('\$ USD')),
                        ],
                        onChanged: (v) {
                          if (v != null) state.updateSettings(settings.copyWith(currencyCode: v));
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: _Field(
                      label: 'Low stock threshold',
                      child: TextField(
                        controller: lowStock,
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        decoration: _decoration(colors),
                        style: TextStyle(fontSize: 13.5, color: colors.ink),
                        onChanged: (v) {
                          final n = int.tryParse(v);
                          if (n != null) state.updateSettings(settings.copyWith(lowStockThreshold: n));
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Default profit margin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.ink2)),
                  Text('${settings.defaultMargin.round()}%', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: colors.greenInk)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(activeTrackColor: colors.green, thumbColor: colors.green),
                child: Slider(
                  value: settings.defaultMargin.clamp(10, 70),
                  min: 10,
                  max: 70,
                  onChanged: (v) => state.updateSettings(settings.copyWith(defaultMargin: v)),
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
              const SectionTitle(title: 'Appearance'),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ThemeButton(
                      label: 'Light',
                      icon: Icons.light_mode_outlined,
                      selected: state.themeMode == ThemeMode.light,
                      onTap: () {
                        if (state.themeMode != ThemeMode.light) state.toggleTheme();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ThemeButton(
                      label: 'Dark',
                      icon: Icons.dark_mode_outlined,
                      selected: state.themeMode == ThemeMode.dark,
                      onTap: () {
                        if (state.themeMode != ThemeMode.dark) state.toggleTheme();
                      },
                    ),
                  ),
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
              const SectionTitle(title: 'Lists'),
              const SizedBox(height: 14),
              _ChipGroup(title: 'Categories', items: kProductCategories),
              const SizedBox(height: 14),
              _ChipGroup(title: 'Units', items: kProductUnits),
              const SizedBox(height: 14),
              _ChipGroup(title: 'Payment methods', items: kPaymentMethods),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Data'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton(
                    onPressed: () => state.showToast('Data backed up locally'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.ink2,
                      side: BorderSide(color: colors.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                    ),
                    child: const Text('Back up data'),
                  ),
                  OutlinedButton(
                    onPressed: () => state.showToast('Restore coming soon'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.ink2,
                      side: BorderSide(color: colors.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                    ),
                    child: const Text('Restore'),
                  ),
                  OutlinedButton(
                    onPressed: () => state.confirm(
                      title: 'Reset sample data?',
                      body: 'This replaces all products, sales and expenses with the original sample dataset. This cannot be undone.',
                      onConfirm: () => state.resetSampleData(),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.red,
                      side: BorderSide(color: colors.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                    ),
                    child: const Text('Reset sample data'),
                  ),
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
              const SectionTitle(title: 'Account'),
              const SizedBox(height: 14),
              Text(
                state.currentUser?.email ?? 'Signed in',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: colors.ink),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => state.confirm(
                  title: 'Sign out?',
                  body: "You'll need to sign in again to see your products, sales and expenses.",
                  onConfirm: () => state.signOut(),
                  confirmLabel: 'Sign out',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.red,
                  side: BorderSide(color: colors.line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                ),
                child: const Text('Sign out'),
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

class _ThemeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeButton({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colors.bg,
          border: Border.all(color: selected ? colors.green : colors.line, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: selected ? colors.greenInk : colors.ink2),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? colors.greenInk : colors.ink2)),
          ],
        ),
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  final String title;
  final List<String> items;
  const _ChipGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.ink2)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: colors.hover, borderRadius: BorderRadius.circular(99)),
                child: Text(item, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.ink2)),
              ),
          ],
        ),
      ],
    );
  }
}
