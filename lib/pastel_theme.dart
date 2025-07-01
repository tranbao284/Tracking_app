import 'package:flutter/material.dart';

class PastelColors {
  static const Color primary = Color(0xFFB5EAEA); // xanh pastel
  static const Color secondary = Color(0xFFFFBCBC); // hồng pastel
  static const Color accent = Color(0xFFFFE2E2); // trắng hồng
  static const Color background = Color(0xFFFFF6F6); // nền trắng kem
  static const Color button = Color(0xFFB5EAEA); // xanh pastel
  static const Color text = Color(0xFF393E46); // xám đậm
  static const Color card = Color(0xFFE3FDFD); // xanh nhạt
  static const Color border = Color(0xFFB5EAEA);
}

final ThemeData pastelTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: PastelColors.primary,
  scaffoldBackgroundColor: PastelColors.background,
  fontFamily: 'Montserrat',
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 32, fontWeight: FontWeight.bold, color: PastelColors.text),
    displayMedium: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 24, fontWeight: FontWeight.bold, color: PastelColors.text),
    bodyLarge: TextStyle(fontFamily: 'NunitoSans', fontSize: 16, color: PastelColors.text),
    bodyMedium: TextStyle(fontFamily: 'NunitoSans', fontSize: 14, color: PastelColors.text),
    labelLarge: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w600, color: PastelColors.text),
  ),
  colorScheme: ColorScheme.light(
    primary: PastelColors.primary,
    secondary: PastelColors.secondary,
    background: PastelColors.background,
    surface: PastelColors.card,
    onPrimary: PastelColors.text,
    onSecondary: PastelColors.text,
    onBackground: PastelColors.text,
    onSurface: PastelColors.text,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: PastelColors.button,
      foregroundColor: PastelColors.text,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
      elevation: 0,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: PastelColors.card,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: PastelColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: PastelColors.primary, width: 2),
    ),
    hintStyle: const TextStyle(color: Colors.grey),
  ),
  cardTheme: CardThemeData(
    color: PastelColors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    elevation: 2,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: PastelColors.primary,
    elevation: 0,
    iconTheme: IconThemeData(color: PastelColors.text),
    titleTextStyle: TextStyle(
      color: PastelColors.text,
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
  ),
); 