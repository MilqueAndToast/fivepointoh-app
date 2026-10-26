import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:five_zero/main.dart';

void main() {
  testWidgets('signed health amount applies damage and healing with Enter', (
    tester,
  ) async {
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
    num damage() =>
        jsonDecode(prefs.getString('five-zero-local-values')!)['Main!AU4'];
    Finder amount() => find.byKey(const ValueKey('health-adjustment-input'));
    Future<void> enter(String value) async {
      await tester.enterText(amount(), value);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    expect(find.text('Damage / Healing'), findsNothing);
    expect(find.text('Take Damage'), findsNothing);
    expect(find.text('Heal'), findsNothing);
    expect(amount(), findsOneWidget);
    await enter('10');
    expect(find.byType(AlertDialog), findsNothing);
    expect(damage(), -8);
    expect(tester.widget<TextField>(amount()).controller!.text, isEmpty);
    await enter('-5');
    expect(find.byType(AlertDialog), findsNothing);
    expect(damage(), -13);
    await enter('NaN');
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Enter a valid number.'), findsOneWidget);
    expect(damage(), -13);
    await tester.enterText(amount(), '-2');
    await tester.tap(find.byKey(const ValueKey('appearance-toggle')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(amount()).controller!.text, '-2');
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    await tester.ensureVisible(amount());
    await enter('2');
    expect(damage(), -11);
    expect(tester.widget<TextField>(amount()).controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
