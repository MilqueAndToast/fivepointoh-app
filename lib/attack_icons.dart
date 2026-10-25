import 'package:flutter/material.dart';
import 'sheet_palette.dart';
import 'category_colors.dart';

const attackVarieties = [
  'Unassigned',
  'Punching',
  'Kicking',
  'Biting',
  'Claw',
  'Hoof',
  'Talon',
  'Pincer',
  'Weapon Slashing',
  'Weapon Thrusting',
  'Weapon Crushing',
  'Whip',
  'Throwing',
  'Shooting via Bow',
  'Shooting via Crossbow',
  'Shooting Short Gun',
  'Shooting Long Gun',
];

String defaultAttackVariety(String name) {
  final n = name.toLowerCase();
  if (n.contains('throw')) return 'Throwing';
  if (n.contains('punch')) return 'Punching';
  if (n.contains('kick')) return 'Kicking';
  if (n.contains('bite')) return 'Biting';
  if (n.contains('claw')) return 'Claw';
  return 'Unassigned';
}

String canonicalDamage(String value) => switch (value.toLowerCase().trim()) {
  'bashing' || 'bludgeoning' || 'bash' => 'Bash',
  'slashing' || 'slash' => 'Slash',
  'piercing' || 'pierce' => 'Pierce',
  _ => value,
};

/// Shared vector glyphs keep the selector, dropdown, and attack details consistent.
class AttackGlyph extends StatelessWidget {
  final String kind;
  final bool damage;
  final double size;
  const AttackGlyph({
    super.key,
    required this.kind,
    this.damage = false,
    this.size = 28,
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: kind == 'Bash'
        ? 'Bashing'
        : kind == 'Slash'
        ? 'Slashing'
        : kind == 'Pierce'
        ? 'Piercing'
        : kind,
    child: Semantics(
      label: '${damage ? 'Damage Type' : 'Attack Variety'}: $kind',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _AttackPainter(
            kind,
            attackCategoryColor(kind, damage, SheetPalette.of(context)),
          ),
        ),
      ),
    ),
  );
}

class _AttackPainter extends CustomPainter {
  final String kind;
  final Color color;
  _AttackPainter(this.kind, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    final pen = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final strokes = <Path>[];
    void drawPath(Path path, Paint _) => strokes.add(path);
    void circle(Offset center, double radius) => strokes.add(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    void path(List<Offset> points, {bool close = false}) {
      final p = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        p.lineTo(point.dx, point.dy);
      }
      if (close) p.close();
      drawPath(p, pen);
    }

    void line(double x, double y, double xx, double yy) =>
        path([Offset(x, y), Offset(xx, yy)]);
    void poly(List<double> xy, {bool close = false}) => path([
      for (var i = 0; i < xy.length; i += 2) Offset(xy[i], xy[i + 1]),
    ], close: close);
    switch (kind) {
      case 'Punching':
        poly([
          8,
          28,
          8,
          21,
          5,
          16,
          5,
          10,
          9,
          10,
          9,
          7,
          13,
          7,
          13,
          6,
          17,
          6,
          17,
          7,
          21,
          7,
          21,
          9,
          25,
          9,
          25,
          19,
          21,
          23,
          21,
          28,
        ], close: true);
        line(9, 10, 9, 16);
        line(13, 8, 13, 14);
        line(17, 8, 17, 14);
        line(21, 10, 21, 15);
        poly([6, 17, 14, 17, 17, 20]);
      case 'Kicking':
        poly([
          10,
          4,
          18,
          4,
          16,
          16,
          25,
          20,
          29,
          24,
          28,
          28,
          15,
          25,
          9,
          20,
          8,
          16,
        ], close: true);
        line(15, 25, 28, 28);
        line(10, 14, 16, 16);
        line(4, 22, 7, 22);
      case 'Biting':
        poly([
          4,
          10,
          7,
          5,
          24,
          5,
          28,
          10,
          24,
          13,
          21,
          8,
          18,
          14,
          15,
          8,
          12,
          14,
          9,
          8,
          6,
          13,
          4,
          10,
        ], close: true);
        poly([
          4,
          22,
          8,
          27,
          24,
          27,
          28,
          22,
          25,
          19,
          22,
          24,
          19,
          18,
          16,
          24,
          13,
          18,
          10,
          24,
          7,
          19,
          4,
          22,
        ], close: true);
      case 'Claw':
        for (var i = 0; i < 3; i++) {
          final x = 7.0 + i * 8;
          drawPath(
            Path()
              ..moveTo(x + 5, 4)
              ..quadraticBezierTo(x - 3, 16, x, 28)
              ..quadraticBezierTo(x + 1, 17, x + 5, 4),
            pen,
          );
        }
      case 'Hoof':
        poly([
          10,
          4,
          22,
          4,
          23,
          14,
          28,
          26,
          25,
          28,
          7,
          28,
          4,
          26,
          9,
          14,
        ], close: true);
        line(9, 14, 23, 14);
        line(16, 19, 16, 28);
        line(6, 24, 13, 24);
        line(19, 24, 26, 24);
      case 'Talon':
        poly([
          13,
          3,
          20,
          3,
          19,
          16,
          27,
          22,
          28,
          28,
          23,
          24,
          17,
          21,
          17,
          27,
          13,
          29,
          13,
          21,
          6,
          25,
          3,
          29,
          4,
          22,
          12,
          16,
        ], close: true);
      case 'Pincer':
        poly([
          12,
          28,
          13,
          20,
          6,
          17,
          3,
          10,
          5,
          4,
          12,
          11,
          11,
          15,
          16,
          17,
          21,
          15,
          20,
          11,
          27,
          4,
          29,
          10,
          26,
          17,
          19,
          20,
          20,
          28,
        ], close: true);
      case 'Weapon Slashing':
        poly([
          7,
          26,
          10,
          23,
          8,
          21,
          12,
          17,
          25,
          4,
          28,
          4,
          28,
          7,
          15,
          20,
          11,
          24,
          9,
          22,
          6,
          25,
        ], close: true);
        drawPath(
          Path()
            ..moveTo(5, 17)
            ..quadraticBezierTo(6, 5, 20, 3),
          pen,
        );
      case 'Weapon Thrusting':
        poly([
          14,
          28,
          18,
          28,
          18,
          15,
          21,
          15,
          16,
          3,
          11,
          15,
          14,
          15,
        ], close: true);
        line(10, 23, 22, 23);
        line(5, 12, 5, 5);
        poly([2, 8, 5, 4, 8, 8]);
        line(27, 12, 27, 5);
        poly([24, 8, 27, 4, 30, 8]);
      case 'Weapon Crushing':
        poly([13, 28, 17, 28, 19, 14, 14, 13], close: true);
        poly([5, 7, 8, 3, 25, 7, 27, 12, 23, 17, 6, 13], close: true);
        line(8, 4, 6, 12);
        line(23, 8, 21, 15);
      case 'Whip':
        poly([4, 28, 8, 29, 13, 20, 10, 18], close: true);
        drawPath(
          Path()
            ..moveTo(12, 19)
            ..cubicTo(28, 22, 31, 7, 23, 5)
            ..cubicTo(14, 1, 9, 12, 18, 13)
            ..quadraticBezierTo(24, 13, 24, 8),
          pen,
        );
      case 'Throwing':
        poly([20, 6, 27, 5, 28, 12, 21, 13], close: true);
        line(23, 8, 25, 10);
        poly([4, 25, 11, 20, 16, 21, 22, 16, 24, 18, 19, 25, 12, 27, 9, 30]);
        drawPath(
          Path()
            ..moveTo(4, 15)
            ..quadraticBezierTo(8, 3, 19, 5),
          pen,
        );
        poly([15, 2, 19, 5, 15, 8]);
      case 'Shooting via Bow':
        drawPath(
          Path()
            ..moveTo(9, 3)
            ..quadraticBezierTo(30, 16, 9, 29),
          pen,
        );
        poly([9, 3, 16, 16, 9, 29]);
        line(4, 16, 29, 16);
        poly([25, 12, 29, 16, 25, 20]);
      case 'Shooting via Crossbow':
        poly([13, 28, 17, 28, 19, 13, 16, 9, 13, 13], close: true);
        drawPath(
          Path()
            ..moveTo(3, 14)
            ..quadraticBezierTo(16, -1, 29, 14),
          pen,
        );
        poly([3, 14, 16, 18, 29, 14]);
        line(16, 5, 16, 21);
        poly([13, 8, 16, 3, 19, 8]);
      case 'Shooting Short Gun':
        poly([
          3,
          8,
          28,
          8,
          28,
          14,
          16,
          14,
          14,
          19,
          11,
          19,
          10,
          27,
          4,
          27,
          7,
          15,
          3,
          15,
        ], close: true);
        poly([16, 14, 20, 14, 18, 20, 13, 20]);
        line(24, 5, 24, 8);
        line(5, 11, 23, 11);
      case 'Shooting Long Gun':
        poly([
          3,
          20,
          8,
          16,
          14,
          16,
          16,
          12,
          29,
          12,
          29,
          16,
          19,
          16,
          17,
          21,
          13,
          21,
          12,
          27,
          8,
          27,
          9,
          21,
          3,
          25,
        ], close: true);
        line(23, 9, 27, 9);
        line(25, 9, 25, 12);
        line(19, 16, 19, 20);
      case 'Slash':
        for (var i = 0; i < 3; i++) {
          final x = 5.0 + i * 8;
          poly([x, 27, x + 10, 4, x + 5, 24]);
        }
      case 'Pierce':
        poly([
          13,
          29,
          13,
          17,
          8,
          17,
          16,
          3,
          24,
          17,
          19,
          17,
          19,
          29,
        ], close: true);
        line(4, 25, 9, 22);
        line(23, 22, 28, 25);
      case 'Bash':
        poly([
          7,
          5,
          25,
          5,
          25,
          13,
          19,
          13,
          19,
          28,
          13,
          28,
          13,
          13,
          7,
          13,
        ], close: true);
        line(3, 17, 7, 20);
        line(29, 17, 25, 20);
        line(5, 27, 9, 25);
        line(27, 27, 23, 25);
      default:
        circle(const Offset(16, 16), 10);
        line(16, 10, 16, 18);
        circle(const Offset(16, 23), .7);
    }
    // Center the drawn artwork, rather than its uneven empty view-box margins.
    // Path.getBounds includes off-curve control points. Measure the actual
    // drawn curves so asymmetric glyphs sit at the center of their button.
    Rect? inkBounds;
    for (final stroke in strokes) {
      for (final metric in stroke.computeMetrics()) {
        final steps = (metric.length * 8).ceil().clamp(8, 2048);
        for (var i = 0; i <= steps; i++) {
          final point = metric
              .getTangentForOffset(metric.length * i / steps)
              ?.position;
          if (point != null) {
            final dot = Rect.fromLTWH(point.dx, point.dy, 0, 0);
            inkBounds = inkBounds == null
                ? dot
                : inkBounds.expandToInclude(dot);
          }
        }
      }
    }
    final bounds = inkBounds ?? const Rect.fromLTWH(0, 0, 32, 32);
    canvas.translate(16 - bounds.center.dx, 16 - bounds.center.dy);
    for (final stroke in strokes) {
      canvas.drawPath(stroke, pen);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AttackPainter old) =>
      old.kind != kind || old.color != color;
}
