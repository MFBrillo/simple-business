import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// One day's worth of bars in a [GroupedBarChart] — 2 or 3 series.
class BarGroup {
  final String dayLabel;
  final List<double> values; // same length/order as [GroupedBarChart.seriesColors]
  const BarGroup({required this.dayLabel, required this.values});
}

/// Grouped vertical bar chart — "Sales, cost & profit / Last 7 days" on the
/// Dashboard, "Sales & profit over time" on Product Details, etc. Hand-rolled
/// (no chart package) since the design only needs plain rounded columns.
class GroupedBarChart extends StatelessWidget {
  final List<BarGroup> groups;
  final List<Color> seriesColors;
  final double maxHeight;

  const GroupedBarChart({
    super.key,
    required this.groups,
    required this.seriesColors,
    this.maxHeight = 150,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final maxValue = groups
        .expand((g) => g.values)
        .fold<double>(0, (m, v) => v > m ? v : m);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return SizedBox(
      height: maxHeight + 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final group in groups)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: maxHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < group.values.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1.5),
                            child: Container(
                              width: 7,
                              height: (group.values[i] / safeMax * maxHeight).clamp(2, maxHeight),
                              decoration: BoxDecoration(
                                color: seriesColors[i % seriesColors.length],
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    group.dayLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Inline legend row: 9px rounded swatches + label, used above chart cards.
class ChartLegend extends StatelessWidget {
  final List<(String, Color)> items;
  const ChartLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final (label, color) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 9, height: 9, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2.5))),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 11.5, color: colors.ink2, fontWeight: FontWeight.w600)),
            ],
          ),
      ],
    );
  }
}

/// One row of a [HorizontalBarChart] — "Profit by product",
/// "Expense breakdown" on Reports.
class HBarItem {
  final String label;
  final double value;
  final Color color;
  const HBarItem({required this.label, required this.value, required this.color});
}

class HorizontalBarChart extends StatelessWidget {
  final List<HBarItem> items;
  final String Function(double value) formatValue;

  const HorizontalBarChart({super.key, required this.items, required this.formatValue});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final maxValue = items.fold<double>(0, (m, i) => i.value > m ? i.value : m);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.label,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colors.ink2),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text(formatValue(item.value),
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: colors.ink)),
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
                          width: constraints.maxWidth * (item.value / safeMax).clamp(0, 1),
                          color: item.color,
                        ),
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
