import 'package:flutter/material.dart';

/// Tema común: colores más vivos y botones redondeados y más grandes.
ThemeData appTheme(Color seed, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  const padding = EdgeInsets.symmetric(horizontal: 22, vertical: 14);
  const label = TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2);
  const minSize = Size(0, 48);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: shape,
        padding: padding,
        textStyle: label,
        minimumSize: minSize,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: shape,
        padding: padding,
        textStyle: label,
        minimumSize: minSize,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: shape,
        padding: padding,
        textStyle: label,
        minimumSize: minSize,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: shape, textStyle: label),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}
