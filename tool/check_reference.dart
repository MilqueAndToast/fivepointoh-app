import 'dart:convert';
import 'dart:io';
import 'package:five_zero/sheet_engine.dart';

void main() {
  final source = jsonDecode(File('assets/reference.json').readAsStringSync());
  final engine = SheetEngine(source['sheets']);
  var checked = 0;
  final differences = <String>[];
  source['sheets'].forEach((String sheet, dynamic cells) {
    cells.forEach((String address, dynamic cell) {
      if (cell['userEnteredValue']?['formulaValue'] == null) return;
      final expected = cell['formattedValue'] ?? '';
      final actual = engine.display(sheet, address);
      checked++;
      if (actual.trim() != expected.toString().trim()) {
        differences.add(
          '$sheet!$address: expected [$expected], actual [$actual]',
        );
      }
    });
  });
  stdout.writeln(
    '$checked formulas checked. ${differences.length} differences.',
  );
  differences.forEach(stdout.writeln);
  engine.errors.forEach((k, v) => stdout.writeln('$k: $v'));
  if (differences.isNotEmpty) exitCode = 1;
}
