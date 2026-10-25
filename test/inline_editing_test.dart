import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:five_zero/main.dart';
import 'package:five_zero/inline_text.dart';
import 'package:five_zero/sheet_engine.dart';
import 'package:five_zero/tabletop_widgets.dart';
import 'dart:io';

void main() {
  testWidgets(
    'inline descriptions, added entries, slot counts and Pack text persist without changing calculations',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1440, 1100);
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
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> saved() =>
          jsonDecode(prefs.getString('five-zero-local-values') ?? '{}');
      Future<void> tapVisible(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tapVisible(find.text('Abilities'));
      final ability = find.byType(InlineText).first;
      final original = tester.widget<InlineText>(ability).text;
      await tapVisible(
        find.descendant(of: ability, matching: find.byType(InkWell)),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'A player description.',
      );
      await tapVisible(find.text('Collapse All'));
      expect(find.widgetWithText(TextField, 'Description'), findsNothing);
      await tapVisible(find.text('Expand All'));
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Description'))
            .controller!
            .text,
        'A player description.',
      );
      await tapVisible(find.text('Cancel'));
      expect(tester.widget<InlineText>(ability).text, original);
      expect(saved(), isEmpty);
      await tapVisible(
        find.descendant(of: ability, matching: find.byType(InkWell)),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'A player description.',
      );
      await tapVisible(find.text('Save'));
      expect(saved().values, contains('A player description.'));
      await tapVisible(find.text('Add Ability').first);
      await tester.enterText(
        find.byKey(const ValueKey('new-entry-name')),
        'Test Talent',
      );
      await tester.enterText(
        find.byKey(const ValueKey('new-entry-description')),
        'An independent feature.',
      );
      await tapVisible(find.text('Add'));
      final abilityKey = saved().entries
          .firstWhere((e) => e.key.startsWith('App!entry_'))
          .key;
      expect(saved()[abilityKey]['group'], 'Class');
      await tapVisible(find.byTooltip('Remove Test Talent'));
      expect(saved()[abilityKey], isNull);
      await tapVisible(find.text('Undo'));
      expect(saved()[abilityKey]['name'], 'Test Talent');

      await tapVisible(find.text('Spellbook'));
      await tapVisible(find.byKey(const ValueKey('add-spell-0')));
      await tester.enterText(
        find.byKey(const ValueKey('new-entry-name')),
        'Test Spark',
      );
      await tester.enterText(
        find.byKey(const ValueKey('new-entry-description')),
        'Single Action\nV,S\n\nDeals 3d6 damage.',
      );
      await tapVisible(find.text('Add'));
      final spellKey = saved().entries
          .firstWhere((e) => e.value is Map && e.value['name'] == 'Test Spark')
          .key;
      expect(saved()[spellKey]['level'], 0);
      await tapVisible(find.byKey(const ValueKey('edit-slots-1')));
      await tester.enterText(find.byKey(const ValueKey('slot-count-1')), '6');
      await tapVisible(find.text('Save'));
      expect(saved()['App!slots_1'], hasLength(6));
      expect(find.byType(TomeCheckbox), findsNWidgets(18));
      await tapVisible(find.bySemanticsLabel('Level 1 Spell Slot 6'));
      expect(saved()['App!slots_1'][5], true);
      await tapVisible(find.text('Light'));
      final light = find.byKey(const ValueKey('inline-Misc!J44'));
      await tapVisible(
        find.descendant(of: light, matching: find.byType(InkWell)),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'Single Action\nV,M\nTouch\n1 Hour\n\nEdited light description.',
      );
      await tapVisible(find.text('Save'));
      expect(saved()['Misc!J44'], contains('Edited light description.'));
      await tapVisible(find.byTooltip('Remove Test Spark'));
      expect(saved()[spellKey], isNull);

      await tapVisible(find.text('Inventory'));
      final pack = find.byKey(const ValueKey('direct-Main!BM18'));
      await tester.ensureVisible(pack);
      await tester.enterText(pack, 'My Adventuring Pack');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(saved()['Main!BM18'], 'My Adventuring Pack');
      expect(saved().keys.any((k) => k.startsWith('Main!BX')), false);
      final source = jsonDecode(
        File('assets/reference.json').readAsStringSync(),
      )['sheets'];
      final before = SheetEngine(source), after = SheetEngine(source, saved());
      for (final sheet in (source as Map).entries) {
        for (final cell in (sheet.value as Map).entries) {
          if (cell.value['userEnteredValue']?['formulaValue'] != null) {
            expect(
              after.value(sheet.key, cell.key),
              before.value(sheet.key, cell.key),
              reason: '${sheet.key}!${cell.key}',
            );
          }
        }
      }
      await tapVisible(find.text('Abilities'));
      expect(find.text('A player description.'), findsOneWidget);
      expect(find.text('Test Talent'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
