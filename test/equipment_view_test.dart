import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:five_zero/equipment_view.dart';
import 'package:five_zero/equipment_figure.dart';

void main() {
  test(
    'removed accessories and underarm flap are absent; boots stay selectable',
    () {
      expect(
        EquipmentFigure.silhouette.contains(const Offset(375, 220)),
        isFalse,
      );
      expect(
        EquipmentFigure.silhouette.contains(const Offset(200, 760)),
        isFalse,
      );
      expect(
        EquipmentFigure.silhouette.contains(const Offset(290, 1000)),
        isFalse,
      );
      for (final point in const [
        Offset(470, 475),
        Offset(472, 450),
        Offset(474, 480),
      ]) {
        expect(EquipmentFigure.silhouette.contains(point), isFalse);
        expect(
          EquipmentFigure.regions.values.any((path) => path.contains(point)),
          isFalse,
        );
      }
      expect(EquipmentFigure.chest.contains(const Offset(485, 470)), isTrue);
      expect(
        EquipmentFigure.silhouette.contains(const Offset(350, 570)),
        isTrue,
      );
      expect(EquipmentFigure.feet.contains(const Offset(290, 1000)), isFalse);
      expect(EquipmentFigure.feet.contains(const Offset(1000, 1000)), isFalse);
      expect(EquipmentFigure.feet.contains(const Offset(350, 1280)), isTrue);
      expect(EquipmentFigure.feet.contains(const Offset(710, 1280)), isTrue);
    },
  );
  test('chest covers the full torso and sword is removed', () {
    expect(EquipmentFigure.chest.contains(const Offset(650, 380)), isTrue);
    expect(EquipmentFigure.chest.contains(const Offset(675, 420)), isTrue);
    expect(EquipmentFigure.chest.contains(const Offset(730, 420)), isFalse);
    expect(EquipmentFigure.chest.contains(const Offset(650, 510)), isFalse);
    expect(
      EquipmentFigure.silhouette.contains(const Offset(1000, 1000)),
      isFalse,
    );
    expect(
      EquipmentFigure.silhouette.contains(const Offset(865, 685)),
      isFalse,
    );
    expect(EquipmentFigure.hands.contains(const Offset(800, 680)), isTrue);
  });
  test('rounded shoulders include upper sleeves and clear the torso', () {
    expect(EquipmentFigure.shoulders.contains(const Offset(420, 280)), isTrue);
    expect(EquipmentFigure.shoulders.contains(const Offset(690, 300)), isTrue);
    expect(EquipmentFigure.shoulders.contains(const Offset(550, 300)), isFalse);
    expect(EquipmentFigure.shoulders.contains(const Offset(420, 380)), isTrue);
    expect(EquipmentFigure.chest.contains(const Offset(690, 300)), isFalse);
    expect(EquipmentFigure.chest.contains(const Offset(650, 380)), isTrue);
  });
  test('broad smooth collar separates the head from the torso', () {
    expect(EquipmentFigure.neck.contains(const Offset(520, 253)), isTrue);
    expect(EquipmentFigure.neck.contains(const Offset(577, 283)), isTrue);
    expect(EquipmentFigure.neck.contains(const Offset(630, 260)), isTrue);
    expect(EquipmentFigure.neck.contains(const Offset(510, 275)), isTrue);
    expect(EquipmentFigure.neck.contains(const Offset(575, 305)), isTrue);
    expect(EquipmentFigure.neck.contains(const Offset(645, 260)), isTrue);
    expect(EquipmentFigure.neck.computeMetrics().length, 1);
    // Each cross-section passes from face to hood, through the full collar,
    // then into Chest. Head never reappears below or inside the collar.
    for (final x in [510.0, 570.0, 630.0]) {
      final runs = <int>[];
      for (var y = 190.5; y < 340; y += 1) {
        final owner = EquipmentFigure.regions.entries
            .singleWhere((entry) => entry.value.contains(Offset(x, y)))
            .key;
        if (runs.isEmpty || runs.last != owner) runs.add(owner);
      }
      expect(runs, [6, 4, 8, 9], reason: 'Head/collar separation at x=$x');
    }
    expect(EquipmentFigure.neck.contains(const Offset(575, 330)), isFalse);
    expect(EquipmentFigure.chest.contains(const Offset(577, 283)), isFalse);
    expect(EquipmentFigure.chest.contains(const Offset(650, 380)), isTrue);
  });
  test('face targets follow the inner hood seam without crossing it', () {
    for (final curve in const [
      [Offset(592, 69), Offset(551, 98), Offset(531, 119)],
      [Offset(531, 119), Offset(513, 149), Offset(494, 178)],
      [Offset(494, 178), Offset(484, 190), Offset(518, 205)],
    ]) {
      for (final t in [0.2, 0.4, 0.6, 0.8]) {
        final edge =
            curve[0] * ((1 - t) * (1 - t)) +
            curve[1] * (2 * (1 - t) * t) +
            curve[2] * (t * t);
        final inside = edge + const Offset(1, 0);
        final outside = edge - const Offset(1, 0);
        expect(EquipmentFigure.faceOpening.contains(inside), isTrue);
        expect(
          EquipmentFigure.band.contains(inside) ||
              EquipmentFigure.eye.contains(inside),
          isTrue,
        );
        expect(EquipmentFigure.hood.contains(outside), isTrue);
        expect(EquipmentFigure.band.contains(outside), isFalse);
        expect(EquipmentFigure.eye.contains(outside), isFalse);
      }
    }
    // In particular, the eye target must stay inside the seam's lower curl.
    expect(EquipmentFigure.hood.contains(const Offset(510, 205)), isTrue);
    expect(EquipmentFigure.eye.contains(const Offset(510, 205)), isFalse);
    expect(EquipmentFigure.eye.contains(const Offset(525, 205)), isTrue);
    expect(EquipmentFigure.band.contains(const Offset(530, 125)), isTrue);
    expect(EquipmentFigure.hood.contains(const Offset(525, 125)), isTrue);
    expect(EquipmentFigure.band.computeMetrics().length, 1);
    expect(EquipmentFigure.eye.computeMetrics().length, 1);
  });
  test('collar and sleeve edges never become stray chest targets', () {
    for (final point in const [
      Offset(666, 236),
      Offset(672, 243),
      Offset(580, 289),
    ]) {
      expect(EquipmentFigure.neck.contains(point), isTrue, reason: '$point');
      expect(EquipmentFigure.chest.contains(point), isFalse);
    }
    for (final point in const [
      Offset(445, 230),
      Offset(389, 310),
      Offset(720, 320),
      Offset(690, 485),
    ]) {
      expect(
        EquipmentFigure.shoulders.contains(point),
        isTrue,
        reason: '$point',
      );
      expect(EquipmentFigure.chest.contains(point), isFalse);
    }
    expect(EquipmentFigure.chest.computeMetrics().length, 1);
  });
  test(
    'wrist regions meet sleeves and gloves exactly at their drawn seams',
    () {
      final seams = [
        (
          [
            const Offset(317, 524),
            const Offset(360, 487),
            const Offset(408.125, 530),
          ],
          7,
          11,
        ),
        (
          [
            const Offset(716.239, 554.215),
            const Offset(755.3305, 531.189),
            const Offset(794.422, 508.163),
          ],
          7,
          11,
        ),
        (
          [
            const Offset(323, 626),
            const Offset(353, 616),
            const Offset(384, 626),
          ],
          11,
          12,
        ),
        (
          [
            const Offset(771.545, 632),
            const Offset(801, 621),
            const Offset(825, 630),
          ],
          11,
          12,
        ),
      ];
      for (final (curve, aboveId, belowId) in seams) {
        for (final t in [0.08, 0.25, 0.5, 0.75, 0.92]) {
          final point =
              curve[0] * ((1 - t) * (1 - t)) +
              curve[1] * (2 * (1 - t) * t) +
              curve[2] * (t * t);
          final above = point - const Offset(0, 0.4);
          final below = point + const Offset(0, 0.4);
          expect(
            EquipmentFigure.regions[aboveId]!.contains(above),
            isTrue,
            reason: 'Slot $aboveId should reach the seam at $above',
          );
          expect(
            EquipmentFigure.regions[belowId]!.contains(below),
            isTrue,
            reason: 'Slot $belowId should start at the seam at $below',
          );
        }
      }
    },
  );
  test('feet and legs meet along the visible curved boot cuffs', () {
    for (final curve in const [
      [Offset(341, 984), Offset(404, 1012), Offset(466, 1008)],
      [Offset(606, 1006), Offset(664, 1023), Offset(733, 1003)],
    ]) {
      for (final t in [0.15, 0.35, 0.5, 0.65, 0.85]) {
        final point =
            curve[0] * ((1 - t) * (1 - t)) +
            curve[1] * (2 * (1 - t) * t) +
            curve[2] * (t * t);
        final above = point - const Offset(0, 2);
        final below = point + const Offset(0, 2);
        expect(EquipmentFigure.legs.contains(above), isTrue, reason: '$above');
        expect(EquipmentFigure.feet.contains(above), isFalse);
        expect(EquipmentFigure.feet.contains(below), isTrue, reason: '$below');
        expect(EquipmentFigure.legs.contains(below), isFalse);
      }
    }
  });
  test(
    'every body point belongs to exactly one slot with intuitive anatomy',
    () {
      for (var y = 16.5; y < 1375; y += 8) {
        for (var x = 270.5; x < 845; x += 8) {
          final point = Offset(x, y);
          final owners = EquipmentFigure.regions.entries
              .where((entry) => entry.value.contains(point))
              .map((entry) => entry.key)
              .toList();
          expect(
            owners.length,
            EquipmentFigure.silhouette.contains(point) ? 1 : 0,
            reason: 'Unexpected slot coverage at $point: $owners',
          );
        }
      }
      final intended = <Offset, int>{
        const Offset(579, 70): 4,
        const Offset(550, 140): 5,
        const Offset(550, 200): 6,
        const Offset(577, 283): 8,
        const Offset(390, 400): 7,
        const Offset(715, 420): 7,
        const Offset(650, 380): 9,
        const Offset(610, 505): 10,
        const Offset(355, 570): 11,
        const Offset(790, 570): 11,
        const Offset(360, 675): 12,
        const Offset(800, 675): 12,
        const Offset(369, 708): 14,
        const Offset(798, 700): 15,
        const Offset(570, 650): 16,
        const Offset(405, 750): 16,
        const Offset(410, 755): 16,
        const Offset(430, 940): 16,
        const Offset(675, 875): 16,
        const Offset(348, 1205): 13,
        const Offset(690, 1200): 13,
      };
      for (final entry in intended.entries) {
        expect(
          EquipmentFigure.regions.entries
              .where((region) => region.value.contains(entry.key))
              .map((region) => region.key),
          [entry.value],
          reason: 'Wrong body intent at ${entry.key}',
        );
      }
      expect(
        EquipmentFigure.silhouette.contains(const Offset(430, 590)),
        isFalse,
      );
      expect(
        EquipmentFigure.silhouette.contains(const Offset(490, 590)),
        isTrue,
      );
    },
  );
  final mainSheet = jsonDecode(
    File('assets/reference.json').readAsStringSync(),
  )['sheets']['Main'];
  final slots = [
    for (var row = 4; row <= 16; row++)
      EquipmentSlot(
        id: row,
        label: mainSheet['BM$row']['formattedValue'],
        item: mainSheet['BQ$row']?['formattedValue'] ?? '',
        description: mainSheet['BQ$row']?['note'] ?? '',
      ),
  ];
  testWidgets(
    'body and labels select the matching item, including empty feet and distinct rings',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      int? edited;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EquipmentView(slots: slots, onEdit: (id) => edited = id),
            ),
          ),
        ),
      );
      expect(find.text('Helmet of Patience'), findsOneWidget);
      for (final entry in <Offset, int>{
        const Offset(525, 125): 4,
        const Offset(530, 125): 5,
        const Offset(510, 205): 4,
        const Offset(525, 205): 6,
        const Offset(666, 236): 8,
        const Offset(580, 289): 8,
        const Offset(445, 230): 7,
        const Offset(720, 320): 7,
        const Offset(690, 485): 7,
        const Offset(585, 405): 9,
        const Offset(404, 996): 16,
        const Offset(404, 1009): 13,
        const Offset(667, 1009): 16,
        const Offset(667, 1018): 13,
        const Offset(390, 400): 7,
        const Offset(715, 420): 7,
        const Offset(355, 570): 11,
        const Offset(790, 570): 11,
        const Offset(360, 675): 12,
        const Offset(800, 675): 12,
        const Offset(369, 708): 14,
        const Offset(798, 700): 15,
        const Offset(610, 505): 10,
        const Offset(570, 650): 16,
        const Offset(348, 1205): 13,
      }.entries) {
        final path = EquipmentFigure.regions[entry.value]!;
        final target = find.byKey(
          ValueKey('equipment-body-slot-${entry.value}'),
        );
        final render = tester.renderObject<RenderBox>(target);
        final scale = render.size.width / path.getBounds().width;
        final point = render.localToGlobal(
          (entry.key - path.getBounds().topLeft) * scale,
        );
        await tester.tapAt(point);
        await tester.pumpAndSettle();
        final item = slots.firstWhere((slot) => slot.id == entry.value).item;
        expect(
          find.text(item.isEmpty ? 'Empty Slot' : item),
          findsOneWidget,
          reason:
              'Physical tap at ${entry.key} should select slot ${entry.value}',
        );
      }

      await tester.tap(find.byKey(const ValueKey('equipment-slot-13')));
      await tester.pumpAndSettle();
      expect(find.text('Empty Slot'), findsOneWidget);
      expect(find.text('Equip Item'), findsOneWidget);
      await tester.tap(find.text('Equip Item'));
      expect(edited, 13);
      await tester.tap(find.byKey(const ValueKey('equipment-slot-15')));
      await tester.pumpAndSettle();
      expect(find.text('Polyamoring'), findsOneWidget);
      final semantics = tester.ensureSemantics();
      await tester.pumpAndSettle();
      // Tap the new traced body shape rather than the previous figure's coordinates.
      await tester.tap(find.bySemanticsLabel('Chest Body Segment'));
      await tester.pumpAndSettle();
      expect(find.text('Blue Scales Armor'), findsOneWidget);
      final headband = tester.getSemantics(
        find.bySemanticsLabel('Headband Body Segment'),
      );
      expect(
        headband.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      headband.owner!.performAction(headband.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(find.text('Rock Mask'), findsOneWidget);
      semantics.dispose();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'medium layouts keep all slot labels beside the figure without overlap',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // Cover a narrow tablet, a wider stacked map, and both ends of the
      // side-by-side map/details layout that previously triggered phone labels.
      for (final width in [520.0, 640.0, 1040.0, 1180.0]) {
        tester.view.physicalSize = Size(width, 1200);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EquipmentView(slots: slots, onEdit: (_) {}),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final figure = tester.getRect(
          find.byKey(const ValueKey('equipment-body')),
        );
        final labels = [
          for (var id = 4; id <= 16; id++)
            tester.getRect(find.byKey(ValueKey('equipment-slot-$id'))),
        ];
        final bodyPaths = find
            .descendant(
              of: find.byType(EquipmentView),
              matching: find.byType(ClipPath),
            )
            .evaluate()
            .map((element) {
              final clip = element.widget as ClipPath;
              final render = tester.renderObject<RenderBox>(
                find.byWidget(clip),
              );
              return clip.clipper!
                  .getClip(render.size)
                  .shift(render.localToGlobal(Offset.zero));
            })
            .toList();
        for (var i = 0; i < labels.length; i++) {
          final label = labels[i];
          expect(label.top, greaterThanOrEqualTo(figure.top - 1e-6));
          expect(
            label.bottom,
            lessThanOrEqualTo(figure.bottom + 1e-6),
            reason: 'Slot ${i + 4} fell below the figure at width $width',
          );
          expect(label.width, greaterThanOrEqualTo(44));
          expect(label.height, greaterThanOrEqualTo(44));
          for (final path in bodyPaths) {
            expect(
              Path.combine(
                PathOperation.intersect,
                path,
                Path()..addRect(label),
              ).computeMetrics().isEmpty,
              isTrue,
              reason: 'Slot ${i + 4} overlaps the body at width $width',
            );
          }
          for (var j = i + 1; j < labels.length; j++) {
            expect(label.overlaps(labels[j]), isFalse);
          }
        }
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'phone labels are touch sized and do not overlap the actual body hit paths',
    (tester) async {
      tester.view.physicalSize = const Size(300, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EquipmentView(slots: slots, onEdit: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final labelRects = [
        for (var id = 4; id <= 16; id++)
          tester.getRect(find.byKey(ValueKey('equipment-slot-$id'))),
      ];
      final segments = find.descendant(
        of: find.byType(EquipmentView),
        matching: find.byType(ClipPath),
      );
      expect(segments, findsWidgets);
      for (var i = 0; i < labelRects.length; i++) {
        expect(labelRects[i].height, greaterThanOrEqualTo(44 - 1e-6));
        expect(labelRects[i].width, greaterThanOrEqualTo(44 - 1e-6));
        for (final segment in segments.evaluate()) {
          final widget = segment.widget as ClipPath;
          final render = tester.renderObject<RenderBox>(find.byWidget(widget));
          final outline = widget.clipper!
              .getClip(render.size)
              .shift(render.localToGlobal(Offset.zero));
          final overlap = Path.combine(
            PathOperation.intersect,
            outline,
            Path()..addRect(labelRects[i]),
          );
          expect(
            overlap.computeMetrics().isEmpty,
            isTrue,
            reason: 'Label ${i + 4} overlaps a body hit shape',
          );
        }
        for (var j = i + 1; j < labelRects.length; j++) {
          expect(labelRects[i].overlaps(labelRects[j]), isFalse);
        }
      }
      expect(find.byType(Tooltip), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'equipment panels stack on a phone and still allow empty-slot selection',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EquipmentView(slots: slots, onEdit: (_) {}),
            ),
          ),
        ),
      );
      final map = tester.getTopLeft(find.text('Equipment Map')),
          details = tester.getTopLeft(find.text('SLOT DETAILS'));
      expect(details.dy, greaterThan(map.dy));
      for (final id in [5, 6, 8, 14, 15]) {
        final target = find.byKey(ValueKey('equipment-slot-$id'));
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(
          find.text(slots.firstWhere((slot) => slot.id == id).item),
          findsOneWidget,
        );
      }
      await tester.ensureVisible(
        find.byKey(const ValueKey('equipment-slot-13')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('equipment-slot-13')));
      await tester.pumpAndSettle();
      expect(find.text('Empty Slot'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
