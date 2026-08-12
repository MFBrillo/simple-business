import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// `linear-gradient(180deg, --green, --green-ink)` hero panel, radius 20,
/// padding 24, white text — used on Add/Edit Product's summary and the
/// Profit Calculator's hero panel.
class GreenHeroPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GreenHeroPanel({super.key, required this.child, this.padding = const EdgeInsets.all(24)});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.green, colors.greenInk],
        ),
        borderRadius: BorderRadius.circular(AppRadius.modal),
      ),
      child: child,
    );
  }
}

/// Translucent white pill used on green hero panels (margin/cost chips).
class HeroPill extends StatelessWidget {
  final String text;
  const HeroPill({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(99)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}
