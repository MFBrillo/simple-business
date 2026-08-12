import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Builds the light/dark [ThemeData] for ProfitPilot, wiring the
/// [AppColors] token set in as a [ThemeExtension] and applying the
/// Plus Jakarta Sans type scale described in `design/README.md`.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(
          bodyColor: colors.ink,
          displayColor: colors.ink,
        );

    return base.copyWith(
      scaffoldBackgroundColor: colors.bg,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        surface: colors.card,
        primary: colors.green,
        error: colors.red,
      ),
      dividerColor: colors.line,
      cardColor: colors.card,
      extensions: [colors],
    );
  }
}

/// Monospace font (IBM Plex Mono) used only for the product-image
/// placeholder caption on the Product Details screen.
TextStyle plexMonoCaption(BuildContext context) => GoogleFonts.ibmPlexMono(
      fontSize: 11.5,
      color: Theme.of(context).extension<AppColors>()!.muted,
    );
