import 'package:flutter/material.dart';

/// Palette "Ferro scuro": sfondo calmo, metallo grigio, colori solo dove servono.
class TrovoColors {
  static const background = Color(0xFF14161B);
  static const surface = Color(0xFF1E2128);
  static const surfaceHigh = Color(0xFF272B34);
  static const surfaceHigher = Color(0xFF323743);
  static const metal = Color(0xFF8A93A3);
  static const metalDark = Color(0xFF5C6474);
  static const metalLight = Color(0xFFB4BCC9);
  static const primary = Color(0xFF00C9A7);
  static const onPrimary = Color(0xFF00211B);
  static const found = Color(0xFFFFD23F);
  static const text = Color(0xFFF2F4F7);
  static const textMuted = Color(0xFFA7AFBC);
  static const danger = Color(0xFFFF6B6B);

  /// Colori dei piani: si ricorda "il piano rosa", non solo "il piano 3".
  /// Il giallo è escluso, perché è riservato all'evidenziazione "trovato".
  static const levelColors = <Color>[
    Color(0xFFFF8A80), // corallo
    Color(0xFFFFB870), // arancio
    Color(0xFF8EE3B5), // menta
    Color(0xFF7CC4FF), // cielo
    Color(0xFFC3A6FF), // lilla
    Color(0xFFF7A1D0), // rosa
    Color(0xFF6FDCD6), // turchese
    Color(0xFFC2E57A), // lime
    Color(0xFFFFC9A3), // pesca
    Color(0xFF9FAEFF), // pervinca
  ];

  static Color level(int index) => levelColors[index % levelColors.length];

  /// Colori degli scaffali (danno anche il nome: "Scaffale Blu").
  static const shelfColors = <Color>[
    Color(0xFF4C8DFF), // blu
    Color(0xFFFF5D5D), // rosso
    Color(0xFF2ECC8F), // verde
    Color(0xFFFF9F43), // arancione
    Color(0xFF9B6BFF), // viola
    Color(0xFFFF6FB5), // rosa
    Color(0xFF2EC5E6), // azzurro
    Color(0xFFB08968), // marrone
  ];

  static Color shelf(int index) => shelfColors[index % shelfColors.length];

  /// Testo scuro o chiaro sopra un colore, per avere sempre contrasto.
  static Color onColor(Color c) =>
      c.computeLuminance() > 0.35 ? const Color(0xFF15171C) : Colors.white;
}

class TrovoTheme {
  static const fontFamily = 'AtkinsonNext';

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: TrovoColors.primary,
      onPrimary: TrovoColors.onPrimary,
      secondary: TrovoColors.found,
      onSecondary: Color(0xFF231A00),
      error: TrovoColors.danger,
      onError: Colors.black,
      surface: TrovoColors.surface,
      onSurface: TrovoColors.text,
      surfaceContainerLowest: TrovoColors.background,
      surfaceContainerLow: TrovoColors.surface,
      surfaceContainer: TrovoColors.surface,
      surfaceContainerHigh: TrovoColors.surfaceHigh,
      surfaceContainerHighest: TrovoColors.surfaceHigher,
      onSurfaceVariant: TrovoColors.textMuted,
      outline: TrovoColors.metalDark,
      outlineVariant: Color(0xFF3A404C),
    );

    const base = TextStyle(
      fontFamily: fontFamily,
      color: TrovoColors.text,
      letterSpacing: 0.2,
      height: 1.3,
    );

    final textTheme = TextTheme(
      displaySmall: base.copyWith(fontSize: 34, fontWeight: FontWeight.w800),
      headlineMedium: base.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
      headlineSmall: base.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge: base.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
      titleMedium: base.copyWith(fontSize: 19, fontWeight: FontWeight.w600),
      titleSmall: base.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
      bodyLarge: base.copyWith(fontSize: 18, fontWeight: FontWeight.w400),
      bodyMedium: base.copyWith(fontSize: 17, fontWeight: FontWeight.w400),
      bodySmall: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: TrovoColors.textMuted,
      ),
      labelLarge: base.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
      labelMedium: base.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      labelSmall: base.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: TrovoColors.background,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: TrovoColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        foregroundColor: TrovoColors.text,
      ),
      cardTheme: CardThemeData(
        color: TrovoColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: textTheme.labelLarge,
          foregroundColor: TrovoColors.text,
          side: const BorderSide(color: TrovoColors.metalDark, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: TrovoColors.primary,
        foregroundColor: TrovoColors.onPrimary,
        extendedTextStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TrovoColors.surfaceHigh,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: textTheme.bodyLarge?.copyWith(color: TrovoColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: TrovoColors.primary, width: 2),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: TrovoColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: TrovoColors.metalDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: TrovoColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: TrovoColors.surfaceHigher,
        contentTextStyle: textTheme.bodyLarge,
        actionTextColor: TrovoColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: TrovoColors.surfaceHigh,
        selectedColor: TrovoColors.primary,
        labelStyle: textTheme.labelMedium,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        iconColor: TrovoColors.textMuted,
        minVerticalPadding: 14,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF2E333D)),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Durate delle animazioni. Con "riduci animazioni" diventano quasi zero.
class Motion {
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, int ms) =>
      reduced(context) ? const Duration(milliseconds: 1) : Duration(milliseconds: ms);
}
