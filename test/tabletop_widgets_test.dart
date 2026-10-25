import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:five_zero/tabletop_widgets.dart';

void main() {
  testWidgets(
    'dice pools render a count and one die per expression, retaining modifiers and wrapping',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 145, child: DiceText('3d10 + 2 and 12d6')),
          ),
        ),
      );
      expect(find.byType(DieIcon), findsNWidgets(2));
      final dice = tester.widgetList<DieIcon>(find.byType(DieIcon));
      expect(dice.where((d) => d.sides == 10).length, 1);
      expect(dice.where((d) => d.sides == 6).length, 1);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('3×'), findsOneWidget);
      expect(find.text('12×'), findsOneWidget);
      expect(find.bySemanticsLabel('3d10 + 2 and 12d6'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('tome checkbox supports accessible checked state and tapping', (
    tester,
  ) async {
    var value = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, set) => TomeCheckbox(
              checked: value,
              label: 'Level 1 Spell Slot 1',
              onChanged: (v) => set(() => value = v),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.widget<TomeCheckbox>(find.byType(TomeCheckbox)).checked,
      isFalse,
    );
    await tester.tap(find.byType(TomeCheckbox));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(find.text('Slot'), findsNothing);
    expect(find.bySemanticsLabel('Level 1 Spell Slot 1'), findsOneWidget);
  });
  test('control labels use initial capitals without changing acronyms', () {
    expect(
      titleCaseLabel('Hit dice remaining (HP)'),
      'Hit Dice Remaining (HP)',
    );
  });
}
