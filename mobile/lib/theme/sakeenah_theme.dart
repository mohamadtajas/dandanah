import 'package:material_ui/material_ui.dart';

/// Colour tokens for the Sakeenah palette.
///
/// The five brand colours are the owner-supplied palette. The remaining values
/// are derived tints for states, borders and the dark theme.
abstract final class SakeenahColors {
  // Brand
  static const green = Color(0xFF0F4B35);
  static const ivory = Color(0xFFF9F8F5);
  static const gold = Color(0xFFC5A059);
  static const ink = Color(0xFF12241F);
  static const sand = Color(0xFFECE7DB);

  // Derived light
  static const greenDark = Color(0xFF0A3527);
  static const greenSoft = Color(0xFFDDE8E2);
  static const goldSoft = Color(0xFFF3E8D2);
  static const goldInk = Color(0xFF6B511A);
  static const muted = Color(0xFF5A665F);
  static const line = Color(0xFFD9D2C3);
  static const error = Color(0xFFB3261E);
  static const errorSoft = Color(0xFFF9DEDC);

  // Derived dark
  static const night = Color(0xFF08120E);
  static const nightSurface = Color(0xFF0F201A);
  static const nightRaised = Color(0xFF172C25);
  static const nightLine = Color(0xFF29433B);
  static const nightMuted = Color(0xFFA6B5AD);
  static const nightError = Color(0xFFFFB4AB);
}

abstract final class SakeenahTheme {
  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: SakeenahColors.gold,
          brightness: Brightness.dark,
        ).copyWith(
          primary: SakeenahColors.gold,
          onPrimary: SakeenahColors.ink,
          primaryContainer: SakeenahColors.nightRaised,
          onPrimaryContainer: SakeenahColors.goldSoft,
          secondary: SakeenahColors.greenSoft,
          onSecondary: SakeenahColors.greenDark,
          secondaryContainer: SakeenahColors.nightRaised,
          onSecondaryContainer: SakeenahColors.ivory,
          surface: SakeenahColors.nightSurface,
          onSurface: SakeenahColors.ivory,
          surfaceContainerLowest: SakeenahColors.night,
          surfaceContainerLow: SakeenahColors.nightSurface,
          surfaceContainer: SakeenahColors.nightRaised,
          surfaceContainerHigh: const Color(0xFF1D352C),
          surfaceContainerHighest: const Color(0xFF244036),
          onSurfaceVariant: SakeenahColors.nightMuted,
          outline: SakeenahColors.nightLine,
          outlineVariant: SakeenahColors.nightRaised,
          error: SakeenahColors.nightError,
          onError: const Color(0xFF690005),
        );
    return _base(
      scheme: scheme,
      scaffold: SakeenahColors.night,
      card: SakeenahColors.nightSurface,
      bar: SakeenahColors.nightSurface,
      gold: true,
    );
  }

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: SakeenahColors.green,
          brightness: Brightness.light,
        ).copyWith(
          primary: SakeenahColors.green,
          onPrimary: SakeenahColors.ivory,
          primaryContainer: SakeenahColors.greenSoft,
          onPrimaryContainer: SakeenahColors.greenDark,
          secondary: SakeenahColors.gold,
          onSecondary: SakeenahColors.ink,
          secondaryContainer: SakeenahColors.goldSoft,
          onSecondaryContainer: SakeenahColors.goldInk,
          surface: SakeenahColors.ivory,
          onSurface: SakeenahColors.ink,
          surfaceContainerLowest: const Color(0xFFFFFFFF),
          surfaceContainerLow: const Color(0xFFF5F2EA),
          surfaceContainer: SakeenahColors.sand,
          surfaceContainerHigh: const Color(0xFFE4DED0),
          surfaceContainerHighest: const Color(0xFFDCD5C6),
          onSurfaceVariant: SakeenahColors.muted,
          outline: SakeenahColors.line,
          outlineVariant: SakeenahColors.sand,
          error: SakeenahColors.error,
          onError: Colors.white,
        );
    return _base(
      scheme: scheme,
      scaffold: SakeenahColors.ivory,
      card: SakeenahColors.sand,
      bar: SakeenahColors.ivory,
      gold: false,
    );
  }

  static ThemeData _base({
    required ColorScheme scheme,
    required Color scaffold,
    required Color card,
    required Color bar,
    required bool gold,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: 'Tajawal',
    );
    final primary = scheme.primary;
    final selectedFill = SakeenahColors.gold;
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: SakeenahColors.green,
        foregroundColor: SakeenahColors.ivory,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: SakeenahColors.ivory),
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700,
          color: SakeenahColors.ivory,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bar,
        surfaceTintColor: Colors.transparent,
        indicatorColor: SakeenahColors.gold.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => base.textTheme.labelMedium?.copyWith(
            fontFamily: 'Tajawal',
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? (gold ? SakeenahColors.gold : SakeenahColors.goldInk)
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? (gold ? SakeenahColors.gold : SakeenahColors.goldInk)
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: scheme.onPrimary,
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: gold ? SakeenahColors.gold : SakeenahColors.green,
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? SakeenahColors.gold
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? SakeenahColors.gold.withValues(alpha: 0.35)
              : scheme.surfaceContainerHigh,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? SakeenahColors.gold
              : scheme.outline,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? SakeenahColors.gold
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(SakeenahColors.ink),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? SakeenahColors.gold
              : scheme.outline,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: SakeenahColors.gold,
        inactiveTrackColor: scheme.outline,
        thumbColor: SakeenahColors.gold,
        overlayColor: SakeenahColors.gold.withValues(alpha: 0.16),
        trackHeight: 4,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: SakeenahColors.gold,
        linearTrackColor: scheme.outlineVariant,
        circularTrackColor: scheme.outlineVariant,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? selectedFill
                : scheme.surfaceContainerLow,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? SakeenahColors.ink
                : scheme.onSurface,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
          iconColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? SakeenahColors.ink
                : scheme.onSurfaceVariant,
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w600),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: SakeenahColors.gold,
        labelStyle: TextStyle(fontSize: 11, color: scheme.onSurface),
        secondaryLabelStyle: const TextStyle(
          fontSize: 11,
          color: SakeenahColors.ink,
        ),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: SakeenahColors.gold, width: 1.6),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SakeenahColors.ink,
        contentTextStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: SakeenahColors.ivory,
        ),
        actionTextColor: SakeenahColors.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: gold ? SakeenahColors.gold : SakeenahColors.green,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: SakeenahColors.gold,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: SakeenahColors.gold,
        foregroundColor: SakeenahColors.ink,
        elevation: 2,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: SakeenahColors.ink,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Tajawal',
          color: SakeenahColors.ivory,
          fontSize: 11,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
        fontFamily: 'Tajawal',
      ),
    );
  }

  /// Large Quran text uses the dedicated Amiri Quran face.
  static TextStyle quran(TextStyle base, {double size = 28}) =>
      base.copyWith(fontFamily: 'AmiriQuran', fontSize: size, height: 1.9);
}
