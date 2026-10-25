import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:five_zero/main.dart';
import 'package:five_zero/sheet_engine.dart';

void main() {
  testWidgets(
    'direct pack, ranks, and resource controls save typed inputs and retain calculations',
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
      final prefs = await SharedPreferences.getInstance();
      final source = jsonDecode(
        File('assets/reference.json').readAsStringSync(),
      )['sheets'];
      Map<String, dynamic> saved() =>
          jsonDecode(prefs.getString('five-zero-local-values') ?? '{}');
      SheetEngine engine() => SheetEngine(source, saved());
      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> type(String id, String text) async {
        final finder = find.byKey(ValueKey('direct-$id'));
        await tester.ensureVisible(finder);
        await tester.enterText(finder, text);
        await tester.pumpAndSettle();
      }

      await tap(find.text('Explore The Rags Reference Locally'));
      expect(find.byTooltip('Edit Turn Resources'), findsNothing);
      await type('Main!AR25', '2');
      await tap(find.text('Save Resources'));
      expect(saved()['Main!AR25'], 2);
      expect(find.text('Save Resources'), findsNothing);
      await tap(find.byKey(const ValueKey('resource-AW25')));
      await tap(find.text('4').last);
      expect(engine().value('Main', 'AT25'), ' / 5');
      // Two quick live controls must both survive the asynchronous saves.
      await tester.tap(find.byKey(const ValueKey('resource-BB25')));
      await tester.tap(find.byKey(const ValueKey('resource-BD25')));
      await tester.pumpAndSettle();
      expect(saved()['Main!BB25'], false);
      expect(saved()['Main!BD25'], false);
      await tap(find.byKey(const ValueKey('resource-BG25')));
      await tap(find.byKey(const ValueKey('resource-AN25')));
      expect(saved()['Main!BG25'], false);
      expect(saved()['Main!AN25'], true);
      await tap(find.byKey(const ValueKey('resource-BJ25')));
      await tap(find.text('3').last);
      expect(saved()['Main!BJ25'], 3);

      await type('Stats!BL8', '11.5');
      await tap(find.text('Save Ranks'));
      expect(
        find.textContaining('must be a nonnegative whole number'),
        findsOneWidget,
      );
      expect(saved().containsKey('Stats!BL8'), false);
      await type('Stats!BL8', '10');
      await tap(find.text('Save Ranks'));
      expect(saved()['Stats!BL8'], 10);
      expect(find.text('Save Ranks'), findsNothing);
      expect(engine().value('Main', 'AK5'), 22);
      await tap(find.byTooltip('Edit Athletics Miscellaneous Bonus'));
      expect(
        find.widgetWithText(TextField, 'Miscellaneous Bonus'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'Skill Ranks'), findsNothing);
      await tap(find.text('Cancel'));

      await tap(find.text('Inventory'));
      expect(find.byTooltip('Edit Pack'), findsNothing);
      final table = find.byKey(const ValueKey('pack-table'));
      expect(
        tester.getSize(table).width,
        lessThanOrEqualTo((1440 - 190 - 40) / 2),
      );
      final qty = find.byKey(const ValueKey('direct-App!pack_quantity_18'));
      final item = find.byKey(const ValueKey('direct-Main!BM18'));
      final weight = find.byKey(const ValueKey('direct-Main!BX18'));
      expect(tester.getTopLeft(qty).dx, lessThan(tester.getTopLeft(item).dx));
      expect(
        tester.getTopLeft(item).dx,
        lessThan(tester.getTopLeft(weight).dx),
      );
      expect(find.text('lb'), findsWidgets);
      await type('Main!BM18', 'Trail pack');
      await type('Main!BX18', 'stone');
      await tap(find.text('Save Pack'));
      expect(
        find.textContaining('must be a nonnegative number'),
        findsOneWidget,
      );
      expect(saved().containsKey('Main!BM18'), false);
      await type('Main!BX18', '25.50');
      await tap(find.byKey(const ValueKey('appearance-toggle')));
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('direct-Main!BX18')))
            .controller!
            .text,
        '25.50',
      );
      await tap(find.text('Save Pack'));
      expect(saved()['Main!BM18'], 'Trail pack');
      expect(saved()['Main!BX18'], 25.5);
      expect(engine().value('Main', 'BX36'), 220.5);
      await type('App!pack_quantity_18', '3');
      await tap(find.text('Save Pack'));
      expect(saved()['App!pack_quantity_18'], 3);
      expect(engine().value('Main', 'BX36'), 271.5);
      await type('App!pack_quantity_18', '-1');
      await tap(find.text('Save Pack'));
      expect(
        find.textContaining('must be a nonnegative whole number'),
        findsOneWidget,
      );
      expect(saved()['App!pack_quantity_18'], 3);
      await tap(find.text('Cancel'));
      expect(find.text('Save Pack'), findsNothing);
      await type('Main!BX18', '1');
      await tap(find.text('Cancel'));
      expect(saved()['Main!BX18'], 25.5);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('direct-Main!BX18')))
            .controller!
            .text,
        '25.5',
      );
      // Clearing an item also clears its weight rather than counting an orphan.
      await type('Main!BM18', '');
      await tap(find.text('Save Pack'));
      expect(saved()['Main!BX18'], isNull);
      expect(saved()['App!pack_quantity_18'], isNull);
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(tester.getSize(table).width, 362);
      expect(tester.widget<TextField>(qty).controller!.text, '1');
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(1440, 1100);
      await tester.pumpAndSettle();
      expect(engine().value('Main', 'BX36'), 195);
      for (final entry in saved().entries) {
        if (entry.key.startsWith('App!')) continue;
        final parts = entry.key.split('!');
        expect(
          source[parts[0]][parts[1]]?['userEnteredValue']?['formulaValue'],
          isNull,
        );
      }
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await tester.pumpWidget(const LedgerApp());
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      await tap(find.text('Explore The Rags Reference Locally'));
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('direct-Stats!BL8')))
            .controller!
            .text,
        '10',
      );
      expect(engine().value('Main', 'AK5'), 22);
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      final misc = find.byTooltip('Edit Athletics Miscellaneous Bonus');
      await tester.ensureVisible(misc);
      expect(tester.getRect(misc).width, greaterThanOrEqualTo(44));
      expect(tester.getRect(misc).height, greaterThanOrEqualTo(44));
      await type('Stats!BL8', '9');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(saved()['Stats!BL8'], 9);
      expect(engine().value('Main', 'AK5'), 21);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
