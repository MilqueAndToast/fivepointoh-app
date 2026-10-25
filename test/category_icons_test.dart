import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:five_zero/attack_icons.dart';
import 'package:five_zero/combat_view.dart';
import 'package:five_zero/category_colors.dart';
import 'package:five_zero/material_theme.dart';
import 'package:five_zero/sheet_palette.dart';

void main() {
  test('semantic colors remain distinct and readable in both themes', () {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
    }

    for (final palette in [SheetPalette.light, SheetPalette.dark]) {
      final abilities = [
        for (final key in abilityCategoryColors.keys)
          abilityCategoryColor(key, palette),
      ];
      expect(abilities.toSet().length, 7);
      for (final color in abilities) {
        expect(contrast(color, palette.background), greaterThanOrEqualTo(4.5));
      }
      final categories = [
        attackCategoryColor('Throwing', false, palette),
        for (final key in ['Bash', 'Slash', 'Pierce'])
          attackCategoryColor(key, true, palette),
      ];
      expect(categories.toSet().length, 4);
      for (final color in categories) {
        expect(contrast(color, palette.background), greaterThanOrEqualTo(4.5));
      }
    }
    expect(
      abilityCategoryColor('INT', SheetPalette.dark),
      const Color(0xff9fc5e8),
    );
  });

  testWidgets(
    'attack cells are adjacent and glyph frames centered within their rules',
    (tester) async {
      const attack = AttackEntry(
        row: 29,
        name: 'Shield Throw',
        variety: 'Throwing',
        damageType: 'Bash',
        damage: '3d6 + 9',
        range: '60',
        critical: '20 x2',
        ammo: '',
        rolls: ['+21', '+16', '+11'],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CombatView(
              attacks: const [attack],
              onEdit: (_) {},
              onAssign: (_, _, _) async {},
            ),
          ),
        ),
      );
      final a = find.byKey(const ValueKey('attack-variety-29-Throwing'));
      final b = find.byKey(const ValueKey('damage-type-29-Bash'));
      final ar = tester.getRect(a), br = tester.getRect(b);
      expect(ar.size, const Size(44, 44));
      expect(br.size, const Size(44, 44));
      expect(ar.right, br.left);
      for (final target in [a, b]) {
        expect(
          tester.getCenter(
            find.descendant(of: target, matching: find.byType(AttackGlyph)),
          ),
          tester.getCenter(target),
        );
      }
    },
  );

  testWidgets(
    'painted artwork stays centered including asymmetric throwing curves',
    (tester) async {
      for (final kind in [...attackVarieties, 'Bash', 'Slash', 'Pierce']) {
        const key = ValueKey('artwork');
        await tester.pumpWidget(
          MaterialApp(
            theme: ledgerMaterialTheme(desktop: true, dark: true),
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: key,
                  child: AttackGlyph(
                    kind: kind,
                    size: 32,
                    damage: ['Bash', 'Slash', 'Pierce'].contains(kind),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );
        final data = await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 3);
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          image.dispose();
          return bytes!.buffer.asUint8List();
        });
        var left = 96, top = 96, right = -1, bottom = -1;
        for (var y = 0; y < 96; y++) {
          for (var x = 0; x < 96; x++) {
            if (data![(y * 96 + x) * 4 + 3] < 40) continue;
            if (x < left) left = x;
            if (x > right) right = x;
            if (y < top) top = y;
            if (y > bottom) bottom = y;
          }
        }
        expect(right, greaterThan(left), reason: kind);
        expect(
          ((left + right) / 2 - 47.5).abs(),
          lessThanOrEqualTo(1),
          reason: '$kind horizontal ink alignment',
        );
        expect(
          ((top + bottom) / 2 - 47.5).abs(),
          lessThanOrEqualTo(1),
          reason: '$kind vertical ink alignment',
        );
      }
    },
  );
}
