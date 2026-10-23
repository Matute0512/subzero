import 'package:flutter/material.dart';

/// Configuración de diseño y paleta de colores oficial para SubZero según Figma Design System.
class AppTheme {
  const AppTheme._();

  // ===========================================================================
  // PALETA CROMÁTICA OFICIAL (FIGMA DESIGN TOKENS)
  // ===========================================================================
  static const Color backgroundDark = Color(0xFF0A192F); // Azul nórdico profundo
  static const Color surface = Color(0xFF112240); // Azul marino de elevación media
  static const Color surfaceVariant = Color(0xFF233554); // Separadores y contornos
  static const Color primaryAccent = Color(0xFF0077B6); // Azul glacial primario
  static const Color secondaryAccent = Color(0xFF48CAE4); // Cian brillante
  static const Color textPrimary = Color(0xFFF8F9FA); // Texto principal de alto contraste
  static const Color textSecondary = Color(0xFF8892B0); // Metadatos y subtítulos

  // ===========================================================================
  // SEMÁFORO DE URGENCIA
  // ===========================================================================
  // Crítico (<= 7 días)
  static const Color urgencyCriticalContainer = Color(0xFF311013);
  static const Color urgencyCriticalAccent = Color(0xFFFF5252);

  // Advertencia (8 - 30 días)
  static const Color urgencyWarningContainer = Color(0xFF2E1E0F);
  static const Color urgencyWarningAccent = Color(0xFFFFA726);

  // Seguro (> 30 días)
  static const Color urgencySafeContainer = Color(0xFF0C2B35);
  static const Color urgencySafeAccent = Color(0xFF00B4D8);

  // ===========================================================================
  // BADGES & PRO TOKENS
  // ===========================================================================
  static const Color goldContainer = Color(0xFF332A15);
  static const Color goldAccent = Color(0xFFFFD166);

  // ===========================================================================
  // GRADIENTES & SOMBRAS
  // ===========================================================================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryAccent, secondaryAccent],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0077B6), Color(0xFF0A192F)],
  );

  static const List<BoxShadow> primaryGlowShadow = [
    BoxShadow(
      color: Color(0x590077B6),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> cyanGlowShadow = [
    BoxShadow(
      color: Color(0x4048CAE4),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  // Aliases para retrocompatibilidad
  static const Color primaryBlue = primaryAccent;
  static const Color deepIce = Color(0xFF03045E);
  static const Color frostyCyan = urgencySafeAccent;
  static const Color lightIce = secondaryAccent;
  static const Color snowWhite = Color(0xFFCAF0F8);
  static const Color darkBackground = backgroundDark;
  static const Color darkSurface = surface;

  // ===========================================================================
  // THEMEDATA
  // ===========================================================================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryAccent,
        brightness: Brightness.dark,
        primary: primaryAccent,
        secondary: secondaryAccent,
        surface: surface,
        surfaceContainerHighest: surfaceVariant,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: surfaceVariant,
        outlineVariant: const Color(0xFF1B2A4A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceVariant, width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryAccent,
        foregroundColor: backgroundDark,
        elevation: 6,
        shape: CircleBorder(),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: backgroundDark,
        modalBackgroundColor: backgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: surfaceVariant, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primaryAccent,
        side: const BorderSide(color: surfaceVariant, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 13,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: surfaceVariant, width: 1),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: backgroundDark,
        headerForegroundColor: textPrimary,
        headerHeadlineStyle: const TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        headerHelpStyle: const TextStyle(
          color: textSecondary,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: surfaceVariant),
        ),
        dividerColor: surfaceVariant,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return backgroundDark;
          if (states.contains(WidgetState.disabled)) {
            return textSecondary.withValues(alpha: 0.38);
          }
          return textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return secondaryAccent;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return backgroundDark;
          return secondaryAccent;
        }),
        todayBorder: const BorderSide(color: secondaryAccent, width: 1.5),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return backgroundDark;
          return textPrimary;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return secondaryAccent;
          return Colors.transparent;
        }),
      ),
    );
  }

  static ThemeData get lightTheme => darkTheme;
}
