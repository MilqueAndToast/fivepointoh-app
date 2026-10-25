import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:five_zero/main.dart';
import 'package:five_zero/inline_text.dart';
import 'package:five_zero/sheet_palette.dart';
import 'package:five_zero/material_theme.dart';

void main() {
  test(
    'both ledger palettes keep ink, annotations and icon categories legible',
    () {
      double contrast(Color a, Color b) {
        final x = a.computeLuminance(), y = b.computeLuminance();
        return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
      }

      for (final palette in [SheetPalette.light, SheetPalette.dark]) {
        for (final color in [
          palette.text,
          palette.aqua,
          palette.muted,
          palette.accent,
          palette.teal,
          palette.concentration,
        ]) {
          expect(
            contrast(color, palette.background),
            greaterThanOrEqualTo(4.5),
          );
        }
        expect(
          contrast(palette.onAccent, palette.accent),
          greaterThanOrEqualTo(4.5),
        );
        expect(palette.surface, palette.background);
      }
      for (final dark in [false, true]) {
        final theme = ledgerMaterialTheme(desktop: true, dark: dark);
        expect(theme.brightness, dark ? Brightness.dark : Brightness.light);
        expect(theme.textTheme.bodyMedium!.fontFamily, 'LedgerSerif');
        expect(theme.dividerTheme.thickness, .7);
      }
    },
  );

  Future<void> launch(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const LedgerApp());
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  final toggle = find.byKey(const ValueKey('appearance-toggle'));
  testWidgets(
    'theme persists across restart and pages while preserving inline drafts and character values',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1440, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await launch(tester);
      expect(find.byTooltip('Switch To Light Mode'), findsOneWidget);
      expect(find.text('Light Mode'), findsNothing);
      final button = tester.getRect(toggle);
      expect(button.width, 44);
      expect(button.height, 44);
      expect(
        tester.getCenter(
          find.descendant(of: toggle, matching: find.byType(Icon)),
        ),
        button.center,
      );
      await tap(tester, toggle);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('five-zero-dark-mode'), false);
      await tester.pumpWidget(const SizedBox());
      await launch(tester);
      expect(find.byTooltip('Switch To Dark Mode'), findsOneWidget);
      await tap(tester, toggle);
      expect(prefs.getBool('five-zero-dark-mode'), true);
      await tap(tester, find.text('Explore The Rags Reference Locally'));
      expect(
        Theme.of(tester.element(find.text('Ragnar "Rags"'))).brightness,
        Brightness.dark,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('quick-notes-input')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('quick-notes-input')),
        'An unsaved journal draft.',
      );
      await tap(tester, toggle);
      expect(prefs.getBool('five-zero-dark-mode'), false);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('quick-notes-input')))
            .controller!
            .text,
        'An unsaved journal draft.',
      );
      await tap(tester, toggle);
      await tap(tester, find.text('Cancel'));
      await tap(tester, find.text('Abilities'));
      final entry = find.byType(InlineText).first;
      await tap(
        tester,
        find.descendant(of: entry, matching: find.byType(InkWell)),
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'An unsaved ability draft.',
      );
      await tap(tester, toggle);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Description'))
            .controller!
            .text,
        'An unsaved ability draft.',
      );
      await tap(tester, find.text('Cancel'));
      await tap(tester, toggle);
      for (final page in [
        'Spellbook',
        'Inventory',
        'Workshop',
        'Activity',
        'Overview',
      ]) {
        await tap(tester, find.text(page));
        expect(
          Theme.of(tester.element(find.text('Ragnar "Rags"'))).brightness,
          Brightness.dark,
        );
        expect(tester.takeException(), isNull);
      }
      expect(prefs.getString('five-zero-local-values'), isNull);
      await tester.pumpWidget(const SizedBox());
      await launch(tester);
      expect(find.byTooltip('Switch To Light Mode'), findsOneWidget);
      await tap(tester, find.text('Explore The Rags Reference Locally'));
      expect(
        Theme.of(tester.element(find.text('Ragnar "Rags"'))).brightness,
        Brightness.dark,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'phone restores dark mode and exposes a single compact toggle and keeps health editing available',
    (tester) async {
      SharedPreferences.setMockInitialValues({'five-zero-dark-mode': true});
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await launch(tester);
      expect(find.byTooltip('Switch To Light Mode'), findsOneWidget);
      await tap(tester, find.text('Explore The Rags Reference Locally'));
      expect(toggle, findsOneWidget);
      await tap(tester, toggle);
      expect(
        Theme.of(tester.element(find.text('Ragnar "Rags"'))).brightness,
        Brightness.light,
      );
      await tap(tester, find.byKey(const ValueKey('hit-dice')));
      expect(
        Theme.of(tester.element(find.byType(AlertDialog))).brightness,
        Brightness.light,
      );
      await tap(tester, find.text('Cancel'));
      expect(find.text('236'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
