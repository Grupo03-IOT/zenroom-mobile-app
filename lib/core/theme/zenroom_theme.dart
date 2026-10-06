import 'package:flutter/material.dart';

class ZenColors {
  static const background = Color(0xFFF4F7FA);
  static const navy = Color(0xFF102D42);
  static const muted = Color(0xFF5C7288);
  static const blue = Color(0xFF3189C6);
  static const paleBlue = Color(0xFFD8EDF9);
  static const border = Color(0xFFD5E0E9);
  static const green = Color(0xFF21813C);
  static const paleGreen = Color(0xFFE4F3E9);
  static const amber = Color(0xFF965C00);
  static const paleAmber = Color(0xFFFFF0D5);
  static const red = Color(0xFFBB2925);
  static const paleRed = Color(0xFFFBE5E5);
}

ThemeData zenroomTheme() {
  const outline = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(6)),
    borderSide: BorderSide(color: ZenColors.border),
  );
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: ZenColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ZenColors.blue,
    ).copyWith(primary: ZenColors.blue, surface: Colors.white),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: ZenColors.navy,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: ZenColors.navy,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ZenColors.navy,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: ZenColors.navy),
      bodySmall: TextStyle(fontSize: 12, color: ZenColors.muted),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: outline,
      enabledBorder: outline,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        borderSide: BorderSide(color: ZenColors.blue, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: TextStyle(color: ZenColors.muted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ZenColors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(38),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
