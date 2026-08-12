import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// KPI card: `--card` bg, 1px `--line`, radius 16, padding 16 17, `--shadow`.
/// Label 12px/600 muted, value 24px/800 tabular-nums, note 11.5px muted.
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? note;
  final Color? valueColor;

  const KpiCard({super.key, required this.label, required this.value, this.note, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(AppRadius.kpi),
        boxShadow: Theme.of(context).brightness == Brightness.dark ? appShadowDark : appShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.muted)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.02,
              color: valueColor ?? colors.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note!, style: TextStyle(fontSize: 11.5, color: colors.muted)),
          ],
        ],
      ),
    );
  }
}

/// `grid-template-columns: repeat(auto-fit, minmax(184px,1fr))` equivalent —
/// wraps KPI cards responsively at a minimum tile width.
class KpiGrid extends StatelessWidget {
  final List<Widget> cards;
  final double minTileWidth;
  const KpiGrid({super.key, required this.cards, this.minTileWidth = 184});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth <= AppBreakpoints.compact;
        final columns = compact ? 2 : (constraints.maxWidth / (minTileWidth + 14)).floor().clamp(1, cards.length);
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final card in cards)
              SizedBox(
                width: (constraints.maxWidth - 14 * (columns - 1)) / columns,
                child: card,
              ),
          ],
        );
      },
    );
  }
}
