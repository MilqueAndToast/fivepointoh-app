import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:five_zero/sheet_engine.dart';

void main() {
  final source = jsonDecode(File('assets/reference.json').readAsStringSync());
  final sheets = Map<String, dynamic>.from(source['sheets']);
  test(
    'inline editing excludes every formula input, including inactive branches and ranges',
    () {
      final sample = SheetEngine({
        'Main': {
          'A1': {
            'userEnteredValue': {'formulaValue': '=IF(FALSE,B1,SUM(C1:C3))'},
          },
        },
      });
      expect(
        sample.calculationInputs,
        containsAll(['Main!B1', 'Main!C1', 'Main!C2', 'Main!C3']),
      );
      expect(sample.calculationLinked('Main', 'A1'), isTrue);
      final engine = SheetEngine(sheets);
      expect(engine.calculationLinked('Main', 'BX18'), isTrue);
      expect(engine.calculationLinked('Main', 'BM18'), isFalse);
      for (final group in [
        ('D', 'M', 6, 35),
        ('D', 'M', 41, 56),
        ('AL', 'AU', 6, 35),
        ('AL', 'AU', 41, 62),
      ]) {
        for (var r = group.$3; r <= group.$4; r++) {
          expect(
            engine.calculationLinked('Abilities', '${group.$1}$r'),
            isFalse,
          );
          expect(
            engine.calculationLinked('Abilities', '${group.$2}$r'),
            isFalse,
          );
        }
      }
    },
  );
  test(
    'all 225 imported formulas match the reference, without cached fallbacks',
    () {
      final engine = SheetEngine(sheets);
      var count = 0;
      sheets.forEach((sheet, cells) {
        (cells as Map).forEach((address, cell) {
          if (cell['userEnteredValue']?['formulaValue'] == null) return;
          expect(
            engine.display(sheet, address).trim(),
            '${cell['formattedValue'] ?? ''}'.trim(),
            reason: '$sheet!$address',
          );
          count++;
        });
      });
      expect(count, 225);
      expect(engine.errors, isEmpty);
    },
  );
  test(
    'sickened changes skills, damage and saves but does not invent an attack penalty',
    () {
      final e = SheetEngine(sheets, {'Main!BF5': true});
      expect(e.value('Main', 'AK5'), 22);
      expect(e.value('Main', 'AS11'), 13);
      expect(e.value('Main', 'AV29'), '+21');
      expect(e.value('Main', 'AY29'), '3d6 + 7');
      // Strong Ideals replaces the normal Will branch in this sheet.
      expect(e.value('Main', 'AS15'), 13);
    },
  );
  test(
    'shield equipment recomputes B&D, and agile repeat attacks retain -4/-8',
    () {
      final e = SheetEngine(sheets, {'Main!BB25': false, 'Main!BD25': false});
      expect(e.value('Main', 'BB9'), 27);
      expect(e.value('Main', 'AW30'), '+17');
      expect(e.value('Main', 'AX30'), '+13');
    },
  );
  test(
    'exhaustion changes ability modifiers, health, and movement through dependencies',
    () {
      final e = SheetEngine(sheets, {'Main!BF16': true});
      expect(e.value('Main', 'X12'), 21);
      expect(e.value('Main', 'AS17'), 20);
      expect(e.value('Stats', 'Q4'), 182);
    },
  );
  test('excess health survives the import and damage updates', () {
    expect(SheetEngine(sheets).value('Main', 'AN4'), '236/218');
    expect(
      SheetEngine(sheets, {'Main!AU4': 10}).value('Main', 'AN4'),
      '208/218',
    );
  });
  test(
    'pack quantities extend weight without replacing imported formulas or unit weights',
    () {
      final base = SheetEngine(sheets);
      expect(base.value('Main', 'BX36'), 195);
      final many = SheetEngine(sheets, {'App!pack_quantity_20': 3});
      expect(many.value('Main', 'BX20'), 40);
      expect(many.value('Main', 'BX36'), 275);
      expect(
        many.cell('Main', 'BX36')['userEnteredValue']['formulaValue'],
        '=SUM(BX18:BY35)',
      );
      expect(
        SheetEngine(sheets, {'App!pack_quantity_20': 0}).value('Main', 'BX36'),
        155,
      );
      expect(
        SheetEngine(sheets, {
          'App!pack_quantity_18': 3,
          'Main!BX18': 5,
          'App!pack_quantity_20': 2,
        }).value('Main', 'BX36'),
        250,
      );
    },
  );
}
