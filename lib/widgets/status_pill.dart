import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum PillTone { green, red, amber, neutral }

/// Small rounded status/category tag: 11px/700, radius 99.
class StatusPill extends StatelessWidget {
  final String label;
  final PillTone tone;
  const StatusPill({super.key, required this.label, this.tone = PillTone.neutral});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, fg) = switch (tone) {
      PillTone.green => (colors.greenSoft, colors.greenInk),
      PillTone.red => (colors.redSoft, colors.red),
      PillTone.amber => (colors.amberSoft, colors.amber),
      PillTone.neutral => (colors.hover, colors.ink2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
