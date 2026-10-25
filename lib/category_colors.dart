import 'package:flutter/material.dart';
import 'sheet_palette.dart';

/// Original sheet pastel hues, with INT using the requested faded blue.
const abilityCategoryColors = <String, Color>{
  'STR': Color(0xffea9999),
  'DEX': Color(0xff87aba1),
  'CON': Color(0xfff9cb9c),
  'INT': Color(0xff9fc5e8),
  'WIS': Color(0xffb4a7d6),
  'CHA': Color(0xffd5a6bd),
  'LUCK': Color(0xfff6b26b),
};

// Paper needs darker ink than the pastel lettering used on evergreen.
Color categoryInk(Color hue, SheetPalette palette) {
  final bg = palette.background.computeLuminance();
  for (var step = 0; step <= 100; step++) {
    final color = Color.lerp(hue, Colors.black, step / 100)!;
    final fg = color.computeLuminance();
    final ratio = ((fg > bg ? fg : bg) + .05) / ((fg < bg ? fg : bg) + .05);
    if (ratio >= 4.5) return color;
  }
  return palette.text;
}

Color abilityCategoryColor(String ability, SheetPalette palette) => categoryInk(
  abilityCategoryColors[ability.toUpperCase().trim()] ?? palette.text,
  palette,
);

Color attackCategoryColor(String kind, bool damage, SheetPalette palette) {
  final key = kind.toLowerCase().trim();
  final Color hue;
  if (!damage) {
    hue = switch (key) {
      'punching' ||
      'kicking' ||
      'biting' ||
      'claw' ||
      'hoof' ||
      'talon' ||
      'pincer' => const Color(0xffe7b08e),
      'unassigned' => palette.muted,
      _ => const Color(0xffed91b3),
    };
  } else {
    hue = switch (key) {
      'bash' || 'bashing' || 'bludgeoning' => const Color(0xff89b9db),
      'slash' || 'slashing' => const Color(0xffe79aa6),
      'pierce' || 'piercing' => const Color(0xffd9b475),
      'fire' => const Color(0xffefad78),
      'cold' || 'ice' => const Color(0xff95cfe4),
      'electricity' || 'lightning' => const Color(0xffddd783),
      'acid' || 'poison' => const Color(0xffa9ce83),
      'psychic' || 'force' => const Color(0xffcaa2dc),
      'radiant' => const Color(0xffe9d29a),
      'necrotic' => const Color(0xffb5a7cf),
      _ => palette.concentration,
    };
  }
  return categoryInk(hue, palette);
}
