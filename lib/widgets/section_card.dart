import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Generic panel card used for chart/table/form sections: `--card` bg,
/// 1px `--line`, radius 18, padding 20 (override via [padding]).
class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SectionCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(AppRadius.panel),
        boxShadow: Theme.of(context).brightness == Brightness.dark ? appShadowDark : appShadowLight,
      ),
      child: child,
    );
  }
}

/// Section title: 15px/800, used at the top of most cards.
class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionTitle({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.ink)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!, style: TextStyle(fontSize: 11.5, color: colors.muted)),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
