import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 2026 Pantone Colors of the Year
  // Primary Colors
  static const Color primaryColor = Color(0xFF3A4A5C);      // PANTONE 18-4218 Blue Fusion (진한 블루 - Main)
  static const Color secondaryColor = Color(0xFF6BA3C7);     // PANTONE 14-4320 Baltic Sea (하늘 블루)
  static const Color accentColor = Color(0xFF9B8FA8);        // PANTONE 16-3610 Quiet Violet (라벤더)
  
  // Background Colors
  static const Color backgroundColor = Color(0xFFF5F3F0);   // PANTONE 11-4201 Cloud Dancer (오프화이트)
  static const Color surfaceColor = Color(0xFFFFFFFF);      // White
  static const Color cardBackgroundColor = Color(0xFFF5F3F0); // PANTONE 11-4201 Cloud Dancer (오프화이트)
  static const Color dividerColor = Color(0xFFB8B5B0);       // PANTONE 16-1523 Cloud Cover (웜 그레이)
  
  // Text Colors
  static const Color textPrimaryColor = Color(0xFF5A5754);   // PANTONE 17-5800 Hematite (다크 그레이)
  static const Color textSecondaryColor = Color(0xFF3A4A5C); // PANTONE 18-4218 Blue Fusion
  static const Color textTertiaryColor = Color(0xFF757575);  // Medium gray
  
  // Accent Colors
  static const Color successColor = Color(0xFFB8D4B8);       // PANTONE 12-6000 Veiled Vista (연한 그린)
  static const Color highlightColor = Color(0xFFE8D8A8);     // PANTONE 13-0624 Golden Mist (골든 옐로우)
  
  // Error Color
  static const Color errorColor = Color(0xFFB00020);
  
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      surface: surfaceColor,
      background: backgroundColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    textTheme: GoogleFonts.robotoTextTheme().copyWith(
      // Display — 대형 타이틀
      displayLarge: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      displayMedium: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      displaySmall: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      // Headline — 화면/카드 제목
      headlineLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      headlineMedium: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      headlineSmall: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      // Title — 카드/리스트 제목, 섹션 제목
      titleLarge: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      titleMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      titleSmall: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      // Body — 본문
      bodyLarge: const TextStyle(
        fontSize: 16,
        color: textPrimaryColor,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        color: textSecondaryColor,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        color: textSecondaryColor,
      ),
      // Label — 버튼·탭·칩·캡션
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondaryColor,
      ),
      labelSmall: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textSecondaryColor,
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 8,
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: BorderSide(
          color: dividerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      shadowColor: Colors.black.withOpacity(0.25),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
  
  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
    ),
    textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      shadowColor: Colors.black.withOpacity(0.2),
    ),
  );
}
