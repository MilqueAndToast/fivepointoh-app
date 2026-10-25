import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:five_zero/spell_card.dart';

void main() {
  test(
    'spell headers extract actions, components, concentration and full names',
    () {
      final spell = SpellDetails.parse(
        'Expedit. Retreat',
        'Expeditious Retreat\nSingle Action\nV, S\nSelf\nConcentration, up to 10 minutes\n\nIncreases movement.',
      );
      expect(spell.name, 'Expeditious Retreat');
      expect(spell.body, startsWith('Self\nUp to 10 minutes'));
      expect(spell.body, isNot(contains('Single Action')));
      expect(spell.body, isNot(contains('V, S')));
      expect(spell.body, isNot(contains('Concentration')));
      expect(spell.actions, ['single']);
      expect(spell.components, {'V', 'S'});
      expect(spell.concentration, true);
      final both = SpellDetails.parse(
        'Counter/Dispell',
        'Counter and Dispel Magic\nDouble Action or Reaction\nS\n60 ft\n\nDispel an effect.',
      );
      expect(both.name, 'Counter and Dispel Magic');
      expect(both.actions, ['double', 'reaction']);
    },
  );
  test(
    'body prose does not invent components or concentration; renamed spells retain the player name',
    () {
      final spell = SpellDetails.parse(
        'My Bolt',
        'Lightning Bolt\nDouble Action\nV,S,M\n\nThe target loses concentration.',
        sourceName: 'Lightning Bolt',
      );
      expect(spell.name, 'My Bolt');
      expect(spell.body, 'The target loses concentration.');
      expect(spell.concentration, false);
      expect(spell.components, {'V', 'S', 'M'});
      final fallback = SpellDetails.parse(
        'Unknown spell',
        '',
        actionHint: '↩/♦♦',
      );
      expect(fallback.actions, containsAll(['double', 'reaction']));
      expect(fallback.components, isEmpty);
    },
  );
  test(
    'icon categories share colors; timing and rule prose survive metadata cleanup',
    () {
      expect(SpellBadge.colorFor('single'), SpellBadge.colorFor('reaction'));
      expect(SpellBadge.colorFor('V'), SpellBadge.colorFor('M'));
      expect(SpellBadge.colorFor('V'), isNot(SpellBadge.colorFor('single')));
      expect(
        SpellBadge.colorFor('concentration'),
        isNot(SpellBadge.colorFor('V')),
      );
      expect(
        SpellBadge.colorFor('concentration'),
        isNot(SpellBadge.colorFor('single')),
      );
      final light = SpellDetails.parse(
        'Light',
        'Single Action\nV,M\nTouch\n1 Hour\n\nCreates light.',
      );
      expect(light.body, 'Touch\n1 Hour\n\nCreates light.');
      final spell = SpellDetails.parse(
        'Telekinesis',
        "Doesn't use a spell slot\nDouble Action\n120 ft\nV, S\n10 minutes, Concentration\n\nOn later turns spend a Single Action.",
      );
      expect(spell.body, contains("Doesn't use a spell slot"));
      expect(spell.body, contains('120 ft\n\n10 minutes'));
      expect(spell.body, contains('On later turns spend a Single Action.'));
      expect(spell.body, isNot(contains('Concentration')));
    },
  );
  testWidgets(
    'collapsed cards keep metadata visible, expand without duplicating the title, and fit mobile width',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SpellCard(
                name: 'Lightning Bolt',
                sourceName: 'Lightning Bolt',
                note:
                    'Lightning Bolt\nDouble Action\nV, S, M\nConcentration, 1 minute\n\nDeals 8d6 damage.',
              ),
            ),
          ),
        ),
      );
      expect(find.text('Lightning Bolt'), findsOneWidget);
      expect(find.byType(SpellBadge), findsNWidgets(5));
      expect(find.textContaining('Deals'), findsNothing);
      await tester.tap(find.text('Lightning Bolt'));
      await tester.pumpAndSettle();
      expect(find.text('Lightning Bolt'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Deals 8d6 damage.')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
