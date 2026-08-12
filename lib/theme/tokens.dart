import 'package:flutter/material.dart';

/// Design tokens ported from `design/README.md` / `Profit Pilot.dc.html`.
///
/// Colors were originally specified in OKLCH; the hex values below are the
/// computed sRGB equivalents (see `design/README.md` for the source OKLCH
/// triples if they ever need to be re-derived).
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color card;
  final Color ink;
  final Color ink2;
  final Color muted;
  final Color line;
  final Color green;
  final Color greenSoft;
  final Color greenInk;
  final Color red;
  final Color redSoft;
  final Color amber;
  final Color amberSoft;
  final Color hover;
  final Color bar;

  const AppColors({
    required this.bg,
    required this.card,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.line,
    required this.green,
    required this.greenSoft,
    required this.greenInk,
    required this.red,
    required this.redSoft,
    required this.amber,
    required this.amberSoft,
    required this.hover,
    required this.bar,
  });

  static const light = AppColors(
    bg: Color(0xFFF4F6F5),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF101613),
    ink2: Color(0xFF2C3733),
    muted: Color(0xFF6D7A74),
    line: Color(0xFFE6EAE8),
    green: Color(0xFF2A9754),
    greenSoft: Color(0xFFDCF7E2),
    greenInk: Color(0xFF006731),
    red: Color(0xFFCB473F),
    redSoft: Color(0xFFFFE5E0),
    amber: Color(0xFFDD9231),
    amberSoft: Color(0xFFFFE9CB),
    hover: Color(0xFFEFF3F0),
    bar: Color(0xFF49595A),
  );

  static const dark = AppColors(
    bg: Color(0xFF0D1211),
    card: Color(0xFF151B19),
    ink: Color(0xFFE9EFEC),
    ink2: Color(0xFFCBD6D1),
    muted: Color(0xFF8F9D97),
    line: Color(0xFF232C29),
    green: Color(0xFF4DBF74),
    greenSoft: Color(0xFF12361E),
    greenInk: Color(0xFF71D790),
    red: Color(0xFFEF675C),
    redSoft: Color(0xFF4B1E1A),
    amber: Color(0xFFF2A548),
    amberSoft: Color(0xFF412706),
    hover: Color(0xFF1C211D),
    bar: Color(0xFF91A2A3),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? card,
    Color? ink,
    Color? ink2,
    Color? muted,
    Color? line,
    Color? green,
    Color? greenSoft,
    Color? greenInk,
    Color? red,
    Color? redSoft,
    Color? amber,
    Color? amberSoft,
    Color? hover,
    Color? bar,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      card: card ?? this.card,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      green: green ?? this.green,
      greenSoft: greenSoft ?? this.greenSoft,
      greenInk: greenInk ?? this.greenInk,
      red: red ?? this.red,
      redSoft: redSoft ?? this.redSoft,
      amber: amber ?? this.amber,
      amberSoft: amberSoft ?? this.amberSoft,
      hover: hover ?? this.hover,
      bar: bar ?? this.bar,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      green: Color.lerp(green, other.green, t)!,
      greenSoft: Color.lerp(greenSoft, other.greenSoft, t)!,
      greenInk: Color.lerp(greenInk, other.greenInk, t)!,
      red: Color.lerp(red, other.red, t)!,
      redSoft: Color.lerp(redSoft, other.redSoft, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberSoft: Color.lerp(amberSoft, other.amberSoft, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      bar: Color.lerp(bar, other.bar, t)!,
    );
  }
}

/// Convenience accessor: `context.colors.green`, etc.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

/// Spacing scale (px): 4 / 6 / 8 / 10 / 13 / 14 / 16 / 18 / 20 / 22 / 24 / 28.
class AppSpacing {
  static const s4 = 4.0;
  static const s6 = 6.0;
  static const s8 = 8.0;
  static const s10 = 10.0;
  static const s13 = 13.0;
  static const s14 = 14.0;
  static const s16 = 16.0;
  static const s18 = 18.0;
  static const s20 = 20.0;
  static const s22 = 22.0;
  static const s24 = 24.0;
  static const s28 = 28.0;
}

/// Radius scale (px): 9 (small buttons) / 11 (buttons, fields) /
/// 13-14 (tiles) / 16 (KPI cards) / 18 (panels) / 20 (modals, hero) / 99 (pills).
class AppRadius {
  static const small = 9.0;
  static const field = 11.0;
  static const tile = 13.0;
  static const tileLg = 14.0;
  static const kpi = 16.0;
  static const panel = 18.0;
  static const modal = 20.0;
  static const pill = 99.0;
}

/// Responsive breakpoints (px).
class AppBreakpoints {
  static const sidebarToTabs = 900.0;
  static const compact = 600.0;
}

const appShadowLight = [
  BoxShadow(color: Color(0x0D101614), offset: Offset(0, 1), blurRadius: 2),
  BoxShadow(color: Color(0x40101614), offset: Offset(0, 8), blurRadius: 24, spreadRadius: -18),
];

const appShadowDark = [
  BoxShadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 2),
];
