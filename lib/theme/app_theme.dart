import 'package:flutter/material.dart';

class AppTheme {
  // Signature Luxury Palette (Luxe Warm Gold & Exact www.esstyle.in Dark Background Palette)
  static const Color luxeGold = Color(0xFFC5A059); // Signature Warm Gold Accent
  static const Color luxeGoldLight = Color(0xFFE5C483);
  static const Color luxeGoldDark = Color(0xFF9E7D3B);
  static const Color luxeGoldAccent = Color(0xFFD4AF37);

  // Exact www.esstyle.in Dark Background Canvas Colors
  static const Color bgDark = Color(0xFF070E1A); // ESSTYLE --bg-page (#070E1A)
  static const Color surfaceDark = Color(0xFF0B1629); // ESSTYLE --bg-surface (#0B1629)
  static const Color surfaceDarkElevated = Color(0xFF0F1E36); // ESSTYLE --bg-card (#0F1E36)
  static const Color borderDark = Color(0xFF1A2B47); // ESSTYLE --dark-border (#1A2B47)

  // Light Mode Canvas (Alabaster Silk & Pure White)
  static const Color bgLight = Color(0xFFF4F6F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Text Colors (Exact ESSTYLE Typography Palette)
  static const Color textDarkPrimary = Color(0xFFF1F5F9); // ESSTYLE --text-main (#F1F5F9)
  static const Color textDarkSecondary = Color(0xFF94A3B8); // ESSTYLE --text-muted (#94A3B8)
  static const Color textDarkMuted = Color(0xFF64748B); // ESSTYLE --text-soft (#64748B)

  static const Color textLightPrimary = Color(0xFF0F172A);
  static const Color textLightSecondary = Color(0xFF334155);
  static const Color textLightMuted = Color(0xFF64748B);

  // Single Unified Luxury Color Swatch Getters
  static const Color primaryColor = luxeGold;
  static const Color emeraldPrimary = luxeGold;
  static const Color cyanPrimary = luxeGold;
  static const Color rosePrimary = luxeGold;
  static const Color violetPrimary = luxeGold;
  static const Color amberPrimary = luxeGold;
  static const Color healthifyCoral = luxeGold;
  static const Color healthifyMint = luxeGold;
  static const Color healthifyTeal = luxeGold;
  static const Color healthifyNavy = luxeGold;
  static const Color healthifyAmber = luxeGold;
  static const Color healthifyViolet = luxeGold;
  static const Color healthifyGreen = luxeGold;
  static const Color healthifyBlue = luxeGold;
  static const Color healthifyOrange = luxeGold;
  static const Color healthifyPurple = luxeGold;
  static const Color healthifyRed = luxeGold;

  static const Color hmePrimary = luxeGold;
  static const Color hmeOrange = luxeGold;
  static const Color hmeTeal = luxeGold;
  static const Color hmeAmber = luxeGold;
  static const Color hmePurple = luxeGold;
  static const Color hmeNavy = luxeGold;
  static const Color hmeCoral = luxeGold;
  static const Color hmeMint = luxeGold;
  static const Color hmeGreen = luxeGold;
  static const Color hmeBlue = luxeGold;

  static const Color surfaceBorder = borderLight;
  static const Color textPrimary = textLightPrimary;
  static const Color textSecondary = textLightSecondary;
  static const Color textMuted = textLightMuted;

  // Single Cohesive Luxe Gradient Preset (Derived from ESSTYLE)
  static const List<Color> goldGradient = [Color(0xFFC5A059), Color(0xFFE5C483)];
  static const List<Color> esstyleHeroGradient = [Color(0xFF07101E), Color(0xFF0B1E38), Color(0xFF0E2A3A)];
  static const List<Color> greenGradient = goldGradient;
  static const List<Color> orangeGradient = goldGradient;
  static const List<Color> tealGradient = goldGradient;
  static const List<Color> coralGradient = goldGradient;
  static const List<Color> mintGradient = goldGradient;
  static const List<Color> emeraldGradient = goldGradient;
  static const List<Color> roseGradient = goldGradient;
  static const List<Color> violetGradient = goldGradient;
  static const List<Color> amberGradient = goldGradient;
  static const List<Color> cyanGradient = goldGradient;

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      primaryColor: luxeGold,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.light(
        primary: luxeGold,
        secondary: luxeGoldDark,
        surface: surfaceLight,
        background: bgLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceLight,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textLightPrimary),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textLightPrimary,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: const CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: borderLight, width: 1),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: luxeGold,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: luxeGold,
        secondary: luxeGoldLight,
        surface: surfaceDark,
        background: bgDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textDarkPrimary),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textDarkPrimary,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: const CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: borderDark, width: 1),
        ),
      ),
    );
  }

  // Executive Luxe Card Decoration
  static BoxDecoration cardDecoration({
    required bool isDark,
    Color? overrideColor,
    Color? borderColor,
    double radius = 16,
    List<BoxShadow>? shadows,
  }) {
    final bgColor = overrideColor ?? (isDark ? surfaceDark : surfaceLight);
    final bColor = borderColor ?? (isDark ? borderDark : borderLight);

    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: bColor, width: 1),
      boxShadow: shadows ??
          [
            BoxShadow(
              color: isDark ? const Color(0x40000000) : const Color(0x0A000000),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
    );
  }

  static BoxDecoration glassDecoration({
    required bool isDark,
    Color? overrideColor,
    Color? borderColor,
    double radius = 16,
    List<BoxShadow>? shadows,
    List<Color>? gradient,
  }) =>
      cardDecoration(
        isDark: isDark,
        overrideColor: overrideColor,
        borderColor: borderColor,
        radius: radius,
        shadows: shadows,
      );

  static BoxDecoration glowingCardDecoration({
    required List<Color> colors,
    double radius = 18,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: luxeGold.withOpacity(0.25),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
