import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:five_zero/main.dart';

void main() {
  testWidgets(
    'hosted browser build opens saved sheet without campaign sign-in',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'five-zero-local-values': jsonEncode({'Main!AU4': 10}),
      });
      tester.view.physicalSize = const Size(1440, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        await tester.pumpWidget(const LedgerApp());
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      expect(find.text('Ragnar "Rags"'), findsOneWidget);
      expect(find.text('208'), findsOneWidget);
      expect(find.text('Enter Campaign'), findsNothing);
      expect(find.text('Back To Sign In'), findsNothing);
      expect(find.byTooltip('Sign Out'), findsNothing);
      expect(
        find.text('SAVED IN THIS BROWSER • use backups to transfer'),
        findsOneWidget,
      );
      final input = find.byKey(const ValueKey('health-adjustment-input'));
      await tester.enterText(input, '5');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('203'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(
        jsonDecode(prefs.getString('five-zero-local-values')!)['Main!AU4'],
        15,
      );
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Sign Out'), findsNothing);
      expect(tester.takeException(), isNull);
    },
    skip: !browserLocalOnly,
  );
}
