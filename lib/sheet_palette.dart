import 'package:flutter/material.dart';

// Ivory/ink daylight; evergreen paper with neutral ivory ink after dark.
const sheetBackground = Color(0xfff8f5ee);
const sheetSurface = sheetBackground;
const sheetTeal = Color(0xff74202a);
const sheetPink = Color(0xff8a1d29);
const sheetAccent = sheetPink;
const sheetMuted = Color(0xff605c59);
const sheetText = Color(0xff171922);
const sheetDeep = Color(0xfff2eee5);
const sheetBorder = Color(0xff92908b);
const sheetAqua = Color(0xff171922);
const sheetSurfaceHigh = Color(0xffebe5d9);
const sheetPrimaryContainer = Color(0xffead9d6);
const sheetCutout = Color(0xff252631);
const sheetVitality = sheetBackground;
const sheetWhite = Color(0xffffffff);

/// The same ledger materials in daylight and lamplight. No extra card surfaces.
@immutable
class SheetPalette {
  final Color background,
      surface,
      teal,
      accent,
      muted,
      text,
      deep,
      border,
      aqua,
      surfaceHigh,
      primaryContainer,
      cutout,
      vitality,
      onAccent,
      concentration;
  const SheetPalette({
    required this.background,
    required this.surface,
    required this.teal,
    required this.accent,
    required this.muted,
    required this.text,
    required this.deep,
    required this.border,
    required this.aqua,
    required this.surfaceHigh,
    required this.primaryContainer,
    required this.cutout,
    required this.vitality,
    required this.onAccent,
    required this.concentration,
  });
  static const light = SheetPalette(
    background: sheetBackground,
    surface: sheetSurface,
    teal: sheetTeal,
    accent: sheetAccent,
    muted: sheetMuted,
    text: sheetText,
    deep: sheetDeep,
    border: sheetBorder,
    aqua: sheetAqua,
    surfaceHigh: sheetSurfaceHigh,
    primaryContainer: sheetPrimaryContainer,
    cutout: sheetCutout,
    vitality: sheetVitality,
    onAccent: sheetWhite,
    concentration: Color(0xff62515b),
  );
  static const dark = SheetPalette(
    background: Color(0xff091413),
    surface: Color(0xff091413),
    deep: Color(0xff060e0d),
    surfaceHigh: Color(0xff18382e),
    text: Color(0xfff3eee4),
    aqua: Color(0xffeee5d5),
    muted: Color(0xffb8b2a8),
    cutout: Color(0xffded6c8),
    border: Color(0xff408a71),
    accent: Color(0xffe8dfcf),
    teal: Color(0xffd1c6b4),
    concentration: Color(0xffcdc4b6),
    primaryContainer: Color(0xff285a48),
    vitality: Color(0xff091413),
    onAccent: Color(0xff091413),
  );
  static SheetPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

// Numeric values use the numeric ink at zero or above and accent below zero.
Color sheetValueColor(
  String value, [
  SheetPalette palette = SheetPalette.light,
]) {
  final text = value.trimLeft();
  if (RegExp(r'^[-−]\s*\d').hasMatch(text)) return palette.accent;
  if (RegExp(r'^\+?\d').hasMatch(text)) return palette.aqua;
  return palette.text;
}
