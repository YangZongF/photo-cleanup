import 'package:flutter/material.dart';

/// Art direction: "Clean Light" (see docs/art-direction.md).
///
/// Light, airy and trustworthy. One calm teal accent, colour-coded
/// categories borrowed from the best cleaner UIs, no scare-red, no
/// fake "junk" numbers, no dark game-like chrome. The photo itself
/// is the visual; the chrome gets out of the way.
class CleanTokens {
  static const Color background = Color(0xFFF7F8F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF14201D);
  static const Color muted = Color(0xFF5C6B66);
  static const Color line = Color(0xFFE3E8E5);

  /// Primary accent: deep teal. Used for the scan button, the keeper
  /// mark and the storage meter.
  static const Color accent = Color(0xFF0E7C6B);
  static const Color accentSoft = Color(0xFFE3F2EE);
  static const Color accentInk = Color(0xFF0A5C50);

  /// Category colours. One colour per category, used for its icon
  /// chip and its card edge, so you always know which tool you are in.
  /// Similars green, screenshots amber, blurry slate, videos coral,
  /// duplicates teal (the accent itself).
  static const Color duplicates = Color(0xFF0E7C6B);
  static const Color similars = Color(0xFF2E9E5B);
  static const Color screenshots = Color(0xFFD9930D);
  static const Color blurry = Color(0xFF64748B);
  static const Color videos = Color(0xFFD95D4E);

  static const double radius = 16;
  static const double gap = 12;
}

ThemeData cleanTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: CleanTokens.accent,
      brightness: Brightness.light,
      surface: CleanTokens.surface,
    ),
    scaffoldBackgroundColor: CleanTokens.background,
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: CleanTokens.background,
      foregroundColor: CleanTokens.ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardTheme(
      color: CleanTokens.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CleanTokens.radius),
        side: const BorderSide(color: CleanTokens.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CleanTokens.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: CleanTokens.accent,
      thumbColor: CleanTokens.accent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? CleanTokens.accent
            : null,
      ),
    ),
  );
}

/// Format a byte count as e.g. "1.2 GB" / "340 MB" / "12 KB".
String formatBytes(int bytes) {
  if (bytes >= 1 << 30) {
    return '${(bytes / (1 << 30)).toStringAsFixed(1)} GB';
  }
  if (bytes >= 1 << 20) {
    return '${(bytes / (1 << 20)).toStringAsFixed(0)} MB';
  }
  if (bytes >= 1 << 10) {
    return '${(bytes / (1 << 10)).toStringAsFixed(0)} KB';
  }
  return '$bytes B';
}
