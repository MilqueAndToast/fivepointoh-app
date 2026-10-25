import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:five_zero/main.dart';

void main() {
  testWidgets(
    'mobile reference dashboard renders and preserves an edited condition',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(430, 932);
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
      expect(find.text('Ragnar "Rags"'), findsOneWidget);
      expect(find.text('236'), findsOneWidget);
      final condition = find.widgetWithText(CheckboxListTile, 'Sickened');
      await tester.ensureVisible(condition);
      await tester.pumpAndSettle();
      await tester.tap(condition);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(condition).value, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('five-zero-local-values'), contains('Main!BF5'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
