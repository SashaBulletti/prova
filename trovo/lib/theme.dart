import 'package:flutter/material.dart';

/// Palette "Dispensa illustrata": carta calda, inchiostro marrone, legno chiaro.
/// Il colore forte è solo il verde basilico (azioni) e il giallo miele (trovato).
class TrovoColors {
  static const background = Color(0xFFF6EFE2); // carta
  static const surface = Color(0xFFFFFBF3); // foglio
  static const surfaceHigh = Color(0xFFF1E7D6);
  static const surfaceHigher = Color(0xFFE8DBC5);
  static const metal = Color(0xFFA08E78); // matita
  static const metalDark = Color(0xFF7A6A58);
  static const metalLight = Color(0xFFC9B9A3);
  static const primary = Color(0xFF3E7B4F); // basilico
  static const onPrimary = Color(0xFFFFFFFF);
  static const found = Color(0xFFF2B92E); // miele
  static const text = Color(0xFF2B2420); // inchiostro
  static const textMuted = Color(0xFF6B5E55);
  static const danger = Color(0xFFB5402F);

  /// Colori dei piani, toni acquerello: si ricorda "il piano rosa", non solo "il piano 3".
  static const levelColors = <Color>[
    Color(0xFFE07A5F),
    Color(0xFFE9B44C),
    Color(0xFF81B29A),
    Color(0xFF6A9FC8),
    Color(0xFFA98BC7),
    Color(0xFFD98AA0),
    Color(0xFF5FAFA3),
    Color(0xFFB9946B),
    Color(0xFFE59866),
    Color(0xFF8E9FD1),
  ];

  static Color level(int index) => levelColors[index % levelColors.length];

  /// Colori dei mobili (danno anche il nome: "Scaffale Blu"), come vernici.
  static const shelfColors = <Color>[
    Color(0xFF4F79B5), // blu
    Color(0xFFC4553F), // rosso
    Color(0xFF5E9A52), // verde
    Color(0xFFE0943A), // arancione
    Color(0xFF8C74B8), // viola
    Color(0xFFD07A92), // rosa
    Color(0xFF4FA3C7), // azzurro
    Color(0xFF8B5E3C), // marrone
  ];

  static Color shelf(int index) => shelfColors[index % shelfColors.length];

  /// Testo scuro o chiaro sopra un colore, per avere sempre contrasto.
  static Color onColor(Color c) => c.computeLuminance() > 0.38 ? text : Colors.white;
}

/// Colori del disegno: inchiostro e legno.
class PaperColors {
  static const ink = Color(0xFF2B2420);
  static const wall = Color(0xFFFBF7EE);
  static const woodLight = Color(0xFFEBC48F);
  static const wood = Color(0xFFD49A5B);
  static const woodDark = Color(0xFFA86B37);
  static const woodEdge = Color(0xFF8A5529);

  /// Contorno a china di card e bottoni, con un'ombra piatta "stampata".
  static List<BoxShadow> printShadow([double dy = 3]) =>
      [BoxShadow(color: ink.withValues(alpha: 0.16), offset: Offset(0, dy))];

  static Border inkBorder([double w = 1.5]) => Border.all(color: ink.withValues(alpha: 0.85), width: w);
}

class TrovoTheme {
  static const fontFamily = 'AtkinsonNext';

  static ThemeData paper() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: TrovoColors.primary,
      onPrimary: TrovoColors.onPrimary,
      secondary: TrovoColors.found,
      onSecondary: TrovoColors.text,
      error: TrovoColors.danger,
      onError: Colors.white,
      surface: TrovoColors.surface,
      onSurface: TrovoColors.text,
      surfaceContainerLowest: TrovoColors.background,
      surfaceContainerLow: TrovoColors.surface,
      surfaceContainer: TrovoColors.surface,
      surfaceContainerHigh: TrovoColors.surfaceHigh,
      surfaceContainerHighest: TrovoColors.surfaceHigher,
      onSurfaceVariant: TrovoColors.textMuted,
      outline: PaperColors.ink,
      outlineVariant: Color(0xFFD9CBB4),
    );

    const base = TextStyle(
      fontFamily: fontFamily,
      color: TrovoColors.text,
      letterSpacing: 0.1,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: PaperColors.ink.withValues(alpha: 0.8), width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: textTheme.labelLarge,
          backgroundColor: TrovoColors.primary,
          foregroundColor: TrovoColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: PaperColors.ink, width: 1.5),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: textTheme.labelLarge,
          foregroundColor: TrovoColors.text,
          backgroundColor: TrovoColors.surface,
          side: const BorderSide(color: PaperColors.ink, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PaperColors.ink, width: 1.8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TrovoColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: textTheme.bodyLarge?.copyWith(color: TrovoColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: PaperColors.ink, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: PaperColors.ink.withValues(alpha: 0.7), width: 1.4),
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
        dragHandleColor: TrovoColors.metal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: TrovoColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: PaperColors.ink,
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: TrovoColors.surface),
        actionTextColor: const Color(0xFFF2C35B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: TrovoColors.surface,
        selectedColor: TrovoColors.primary,
        labelStyle: textTheme.labelMedium,
        side: BorderSide(color: PaperColors.ink.withValues(alpha: 0.8), width: 1.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        iconColor: TrovoColors.textMuted,
        minVerticalPadding: 14,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFDCCDB5)),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: TrovoColors.surface,
          foregroundColor: TrovoColors.text,
          side: const BorderSide(color: PaperColors.ink, width: 1.4),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: TrovoColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: PaperColors.ink, width: 1.4),
        ),
      ),
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
