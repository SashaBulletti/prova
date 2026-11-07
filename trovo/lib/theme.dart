import 'package:flutter/material.dart';

/// Palette "Trovo – Vetro": fondo scuro profondo, vetro, colore usato come filo o punto.
class TrovoColors {
  static const background = Color(0xFF0A0C11);

  /// Superfici piene (quando serve un fondo opaco, es. "vetro solido").
  static const surface = Color(0xFF151820);
  static const surfaceHigh = Color(0xFF1C1F27);
  static const surfaceHigher = Color(0xFF252932);
  static const solidGlass = Color(0xF71A1D24);

  /// Metallo satinato.
  static const metal = Color(0xFF6A707C);
  static const metalDark = Color(0xFF2B2F37);
  static const metalLight = Color(0xFF8C93A0);

  static const text = Color(0xFFF4F6FA);
  static const textMuted = Color(0xADF4F6FA); // α 0.68
  static const textFaint = Color(0x73F4F6FA); // α 0.45 (solo decorazioni)

  /// Accento: pieno, su vetro (testo/icone) e testo sopra l'accento.
  static const primary = Color(0xFF00C9A7);
  static const primaryOnGlass = Color(0xFF2FE0C0);
  static const onPrimary = Color(0xFF032620);
  static const primaryEnd = Color(0xFF14A3C7);

  static const found = Color(0xFFFFCC33);
  static const low = Color(0xFFFFB547);
  static const danger = Color(0xFFFF7A7A);

  /// Colori dei piani, toni "gioiello": sempre insieme al numero.
  static const levelColors = <Color>[
    Color(0xFFF2836B),
    Color(0xFFF0A953),
    Color(0xFF6FCF97),
    Color(0xFF3FC1C9),
    Color(0xFF5B9CF5),
    Color(0xFF9B87F5),
    Color(0xFFE07FA8),
    Color(0xFFCDB58A),
  ];

  static Color level(int index) => levelColors[index % levelColors.length];

  /// Colori dei mobili (danno il nome: "Scaffale Blu"). Stesso ordine dei nomi.
  static const shelfColors = <Color>[
    Color(0xFF5B9CF5), // blu
    Color(0xFFF2836B), // rosso
    Color(0xFF6FCF97), // verde
    Color(0xFFF0A953), // arancione
    Color(0xFF9B87F5), // viola
    Color(0xFFE07FA8), // rosa
    Color(0xFF3FC1C9), // azzurro
    Color(0xFFCDB58A), // sabbia
  ];

  static Color shelf(int index) => shelfColors[index % shelfColors.length];

  /// Testo scuro o chiaro sopra un colore, per avere sempre contrasto.
  static Color onColor(Color c) => c.computeLuminance() > 0.3 ? background : Colors.white;
}

class TrovoTheme {
  static const fontFamily = 'AtkinsonNext';

  static const _tabular = [FontFeature.tabularFigures()];

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: TrovoColors.primary,
      onPrimary: TrovoColors.onPrimary,
      secondary: TrovoColors.found,
      onSecondary: TrovoColors.background,
      error: TrovoColors.danger,
      onError: TrovoColors.background,
      surface: TrovoColors.surface,
      onSurface: TrovoColors.text,
      surfaceContainerLowest: TrovoColors.background,
      surfaceContainerLow: TrovoColors.surface,
      surfaceContainer: TrovoColors.surface,
      surfaceContainerHigh: TrovoColors.surfaceHigh,
      surfaceContainerHighest: TrovoColors.surfaceHigher,
      onSurfaceVariant: TrovoColors.textMuted,
      outline: Color(0x29FFFFFF),
      outlineVariant: Color(0x1AFFFFFF),
    );

    const base = TextStyle(
      fontFamily: fontFamily,
      color: TrovoColors.text,
      fontFeatures: _tabular,
    );

    final textTheme = TextTheme(
      displaySmall: base.copyWith(fontSize: 34, height: 40 / 34, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      headlineMedium: base.copyWith(fontSize: 34, height: 40 / 34, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      headlineSmall: base.copyWith(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w600),
      titleLarge: base.copyWith(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w600),
      titleMedium: base.copyWith(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w600),
      titleSmall: base.copyWith(fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w600),
      bodyLarge: base.copyWith(fontSize: 17, height: 25 / 17, fontWeight: FontWeight.w400),
      bodyMedium: base.copyWith(fontSize: 17, height: 25 / 17, fontWeight: FontWeight.w400),
      bodySmall: base.copyWith(fontSize: 15, height: 21 / 15, fontWeight: FontWeight.w400, color: TrovoColors.textMuted),
      labelLarge: base.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
      labelMedium: base.copyWith(fontSize: 14, height: 18 / 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      labelSmall: base.copyWith(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.2),
    );

    final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(26));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: TrovoColors.background,
      splashFactory: InkSparkle.splashFactory,
      highlightColor: Colors.white.withValues(alpha: 0.04),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleSmall,
        foregroundColor: TrovoColors.text,
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.06),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: textTheme.labelLarge,
          backgroundColor: TrovoColors.primary,
          foregroundColor: TrovoColors.onPrimary,
          shape: pill,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: textTheme.labelLarge,
          foregroundColor: TrovoColors.primaryOnGlass,
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
          shape: pill,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelLarge,
          foregroundColor: TrovoColors.primaryOnGlass,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: TrovoColors.text, minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: textTheme.bodyLarge?.copyWith(color: TrovoColors.textFaint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: TrovoColors.primaryOnGlass, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBarrierColor: Color(0x59000000),
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: TrovoColors.solidGlass,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xF2232731),
        contentTextStyle: textTheme.bodyLarge,
        actionTextColor: TrovoColors.primaryOnGlass,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        selectedColor: TrovoColors.primary.withValues(alpha: 0.22),
        labelStyle: textTheme.labelMedium,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          foregroundColor: TrovoColors.text,
          selectedBackgroundColor: TrovoColors.primary.withValues(alpha: 0.24),
          selectedForegroundColor: TrovoColors.primaryOnGlass,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          textStyle: textTheme.labelMedium,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? TrovoColors.primary : Colors.white.withValues(alpha: 0.12),
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? TrovoColors.onPrimary : TrovoColors.textMuted,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        iconColor: TrovoColors.textMuted,
        minVerticalPadding: 14,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: TrovoColors.solidGlass,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        textStyle: textTheme.bodyLarge,
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.08)),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: TrovoColors.primaryOnGlass),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
      ),
    );
  }
}

/// Durate e curve delle animazioni. Con "riduci animazioni" diventano dissolvenze brevi.
class Motion {
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, int ms) =>
      reduced(context) ? const Duration(milliseconds: 1) : Duration(milliseconds: ms);

  /// Curve "a molla" sobrie (niente rimbalzi esagerati).
  static const standard = Cubic(0.2, 0.9, 0.25, 1.0);
  static const snappy = Cubic(0.3, 1.25, 0.4, 1.0);
  static const confirm = Cubic(0.34, 1.4, 0.5, 1.0);
}
