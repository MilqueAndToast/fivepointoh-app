import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:five_zero/main.dart';
import 'package:five_zero/combat_view.dart';
import 'package:five_zero/parchment_notes.dart';
import 'package:five_zero/attack_icons.dart';

void main() {
  testWidgets(
    'selected attack icon assignments persist independently and notes consolidate without loss',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await tester.pumpWidget(const LedgerApp());
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore The Rags Reference Locally'));
      await tester.pumpAndSettle();
      final selector = find.byKey(const ValueKey('attack-selector-29'));
      await tester.ensureVisible(selector);
      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Punch').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('attack-selector-30')), findsOneWidget);
      // Only one set of three attack rolls is rendered.
      expect(
        find.descendant(
          of: find.byType(CombatView),
          matching: find.byType(Chip),
        ),
        findsNWidgets(3),
      );
      final variety = find.byKey(const ValueKey('attack-variety-30-Punching'));
      await tester.ensureVisible(variety);
      await tester.tap(variety);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Claw').last);
      await tester.pumpAndSettle();
      final damage = find.byKey(const ValueKey('damage-type-30-Bash'));
      await tester.ensureVisible(damage);
      await tester.tap(damage);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Piercing').last);
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      var saved = jsonDecode(prefs.getString('five-zero-local-values')!) as Map;
      expect(saved['Misc!BZ30'], 'Claw');
      expect(saved['Main!BD30'], 'Pierce');
      expect(saved.containsKey('Misc!BZ29'), isFalse);
      expect(
        tester
            .widget<CombatView>(find.byType(CombatView))
            .attacks
            .first
            .damageType,
        'Bash',
      );
      final notes = find.byKey(const ValueKey('quick-notes-input'));
      final previous = tester.widget<TextField>(notes).controller!.text;
      expect(previous, contains('Common, Basic, Mammalian'));
      expect(previous, contains('Champion of Greed'));
      await tester.ensureVisible(notes);
      await tester.enterText(notes, '$previous\nMeet the DM at dawn.');
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('save-quick-notes')),
      );
      await tester.tap(find.byKey(const ValueKey('save-quick-notes')));
      await tester.pumpAndSettle();
      saved = jsonDecode(prefs.getString('five-zero-local-values')!) as Map;
      expect(saved['Main!B25'], '$previous\nMeet the DM at dawn.');
      for (var row = 26; row <= 36; row++) {
        expect(saved['Main!B$row'], isNull);
      }
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Overview'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(notes).controller!.text,
        '$previous\nMeet the DM at dawn.',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('combat controls and parchment input fit a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CombatView(
                    attacks: const [
                      AttackEntry(
                        row: 29,
                        name: 'A very long named attack',
                        variety: 'Shooting via Crossbow',
                        damageType: 'Slash',
                        damage: '8d6 + 10',
                        range: '60',
                        critical: '20 x2',
                        ammo: '12',
                        rolls: ['+21', '+16', '+11'],
                      ),
                    ],
                    onEdit: (_) {},
                    onAssign: (_, _, _) async {},
                  ),
                  ParchmentNotes(
                    text: 'A note from the last adventure.',
                    onSave: (_) async {},
                    onEditingChanged: (_) {},
                  ),
                  Wrap(
                    children: [
                      for (final kind in attackVarieties)
                        AttackGlyph(kind: kind),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
