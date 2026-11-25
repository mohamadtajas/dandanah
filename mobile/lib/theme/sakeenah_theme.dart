import 'package:material_ui/material_ui.dart';

/// Colour tokens shared with the desktop app.
abstract final class SakeenahColors {
  static const ink950 = Color(0xFF07090E);
  static const ink900 = Color(0xFF0B0E15);
  static const ink850 = Color(0xFF0F1320);
  static const ink800 = Color(0xFF141A29);
  static const line = Color(0xFF232C42);
  static const cream = Color(0xFFF3EFE5);
  static const muted = Color(0xFF8C94A9);
  static const gold = Color(0xFFE9B95C);
  static const goldSoft = Color(0xFFF5D9A0);
  static const teal = Color(0xFF57B8AC);

  static const paper = Color(0xFFFDFBF7);
  static const paperDeep = Color(0xFFF6F3EC);
  static const paperLine = Color(0xFFDDD5C5);
  static const paperInk = Color(0xFF1B1A17);
  static const paperMuted = Color(0xFF6F6D66);
  static const goldInk = Color(0xFFA56F1D);
  static const tealInk = Color(0xFF2F7D75);
}

abstract final class SakeenahTheme {
  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: SakeenahColors.gold,
          brightness: Brightness.dark,
        ).copyWith(
          primary: SakeenahColors.gold,
          onPrimary: SakeenahColors.ink950,
          primaryContainer: SakeenahColors.ink800,
          onPrimaryContainer: SakeenahColors.goldSoft,
          secondary: SakeenahColors.teal,
          onSecondary: SakeenahColors.ink950,
          surface: SakeenahColors.ink900,
          onSurface: SakeenahColors.cream,
          onSurfaceVariant: SakeenahColors.muted,
          outline: SakeenahColors.line,
          outlineVariant: SakeenahColors.ink800,
          error: const Color(0xFFEF6B6B),
          onError: SakeenahColors.ink950,
        );
    return _base(
      scheme: scheme,
      scaffold: SakeenahColors.ink950,
      card: SakeenahColors.ink900,
      bar: SakeenahColors.ink900,
    );
  }

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: SakeenahColors.goldInk,
          brightness: Brightness.light,
        ).copyWith(
          primary: SakeenahColors.goldInk,
          onPrimary: Colors.white,
          primaryContainer: SakeenahColors.paperDeep,
          onPrimaryContainer: SakeenahColors.goldInk,
          secondary: SakeenahColors.tealInk,
          onSecondary: Colors.white,
          surface: SakeenahColors.paper,
          onSurface: SakeenahColors.paperInk,
          onSurfaceVariant: SakeenahColors.paperMuted,
          outline: SakeenahColors.paperLine,
          outlineVariant: SakeenahColors.paperDeep,
          error: const Color(0xFFB3261E),
        );
    return _base(
      scheme: scheme,
      scaffold: SakeenahColors.paper,
      card: SakeenahColors.paper,
      bar: SakeenahColors.paperDeep,
    );
  }

  static ThemeData _base({
    required ColorScheme scheme,
    required Color scaffold,
    required Color card,
    required Color bar,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: 'Tajawal',
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
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
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => base.textTheme.labelMedium?.copyWith(
            fontFamily: 'Tajawal',
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// Large Quran text uses the dedicated Amiri Quran face.
  static TextStyle quran(TextStyle base, {double size = 28}) =>
      base.copyWith(fontFamily: 'AmiriQuran', fontSize: size, height: 1.9);
}
