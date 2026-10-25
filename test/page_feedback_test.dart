import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:five_zero/main.dart';
import 'package:five_zero/tabletop_widgets.dart';
import 'package:five_zero/spell_card.dart';
import 'package:five_zero/equipment_view.dart';

void main() {
  testWidgets(
    'hit dice, abilities, spell notes, and saved tome slots follow page feedback',
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
      await tester.tap(find.byKey(const ValueKey('hit-dice')));
      await tester.pumpAndSettle();
      expect(find.text('Hit Dice Remaining'), findsOneWidget);
      expect(find.textContaining('Damage taken'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abilities'));
      await tester.pumpAndSettle();
      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.textContaining('As a Reaction, If an enemy'), findsOneWidget);
      expect(
        (tester.getCenter(find.text('Shield Throw')).dy -
                tester.getCenter(find.text('Level 1').first).dy)
            .abs(),
        lessThan(1),
      );
      await tester.tap(find.byTooltip('Collapse Interception'));
      await tester.pumpAndSettle();
      expect(find.text('Interception'), findsOneWidget);
      expect(find.textContaining('As a Reaction, If an enemy'), findsNothing);
      await tester.tap(find.text('Collapse All'));
      await tester.pumpAndSettle();
      expect(find.text('Expand All'), findsOneWidget);
      expect(
        find.textContaining('Bastions can Throw their Shield'),
        findsNothing,
      );
      expect(find.text('Level 1'), findsWidgets);
      await tester.tap(find.byTooltip('Expand Interception'));
      await tester.pumpAndSettle();
      expect(find.textContaining('As a Reaction, If an enemy'), findsOneWidget);
      await tester.tap(find.text('Collapse All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expand All'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Bastions can Throw their Shield'),
        findsOneWidget,
      );
      await tester.tap(find.text('Spellbook'));
      await tester.pumpAndSettle();
      expect(find.byType(TomeCheckbox), findsNWidgets(16));
      expect(find.text('Slot'), findsNothing);
      expect(find.textContaining('You can touch an item'), findsNothing);
      await tester.tap(find.text('Expand All'));
      await tester.pumpAndSettle();
      expect(find.text('Collapse All'), findsOneWidget);
      expect(find.textContaining('You can touch an item'), findsOneWidget);
      await tester.tap(find.text('Collapse All'));
      await tester.pumpAndSettle();
      expect(find.textContaining('You can touch an item'), findsNothing);
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(find.textContaining('You can touch an item'), findsOneWidget);
      final first = find.byType(TomeCheckbox).first;
      await tester.ensureVisible(first);
      await tester.pumpAndSettle();
      await tester.tap(first);
      await tester.pumpAndSettle();
      expect(tester.widget<TomeCheckbox>(first).checked, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('five-zero-local-values'),
        contains('"Main!M42":false'),
      );
      await tester.enterText(find.byType(TextField), 'Lightning Bolt');
      await tester.pumpAndSettle();
      final bolt = find.descendant(
        of: find.byType(SpellCard),
        matching: find.text('Lightning Bolt'),
      );
      await tester.ensureVisible(bolt);
      await tester.tap(bolt);
      await tester.pumpAndSettle();
      expect(find.byType(DieIcon), findsNWidgets(2));
      expect(find.text('8×'), findsOneWidget);
      expect(find.text('1×'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('toggle-all-spells')),
      );
      await tester.tap(find.text('Expand All'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.textContaining('You can touch an item'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Lightning');
      await tester.tap(find.text('Inventory'));
      await tester.pumpAndSettle();
      expect(find.text('Helmet of Patience'), findsOneWidget);
      final feet = find.byKey(const ValueKey('equipment-slot-13'));
      await tester.ensureVisible(feet);
      await tester.tap(feet);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Equip Item'));
      await tester.tap(find.text('Equip Item'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Item Name'),
        'Boots of Testing',
      );
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.text('Boots of Testing'), findsOneWidget);
      expect(
        tester
            .widget<EquipmentView>(find.byType(EquipmentView))
            .slots
            .firstWhere((s) => s.id == 13)
            .equipped,
        isTrue,
      );
      expect(
        prefs.getString('five-zero-local-values'),
        contains('Boots of Testing'),
      );
      await tester.tap(find.text('Abilities'));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(360, 800);
      await tester.pumpAndSettle();
      final collapseShield = find.byTooltip('Collapse Shield Throw');
      await tester.ensureVisible(collapseShield);
      await tester.tap(collapseShield);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Expand Shield Throw'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
