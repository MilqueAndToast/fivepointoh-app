import 'sheet_palette.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

String titleCaseLabel(String text) => text.replaceAllMapped(
  RegExp(r'\b[a-zA-Z][a-zA-Z’\x27]*'),
  (m) => '${m[0]![0].toUpperCase()}${m[0]!.substring(1)}',
);

/// A text replacement for display values; editors keep ordinary notation.
/// Each dice pool is a compact count and one die, kept together when wrapping.
class DiceText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;
  const DiceText(
    this.data, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  });
  static final notation = RegExp(r'\b(\d+)\s*[dD]\s*(\d+)\b');
  @override
  Widget build(BuildContext context) {
    final matches = notation
        .allMatches(data)
        .where((m) => int.parse(m[1]!) > 0 && int.parse(m[2]!) >= 2)
        .toList();
    if (matches.isEmpty) {
      return Text(
        data,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
        softWrap: softWrap,
      );
    }
    final effective = DefaultTextStyle.of(context).style.merge(style);
    final size = ((effective.fontSize ?? 14) * 1.8).clamp(25.0, 44.0);
    final color = effective.color ?? Theme.of(context).colorScheme.onSurface;
    final spans = <InlineSpan>[];
    var offset = 0;
    for (final m in matches) {
      if (m.start > offset) {
        spans.add(TextSpan(text: data.substring(offset, m.start)));
      }
      final count = int.parse(m[1]!), sides = int.parse(m[2]!);
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$count×', style: effective),
                const SizedBox(width: 3),
                DieIcon(sides: sides, size: size, color: color),
              ],
            ),
          ),
        ),
      );
      offset = m.end;
    }
    if (offset < data.length) spans.add(TextSpan(text: data.substring(offset)));
    return Semantics(
      label: data,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(style: effective, children: spans),
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
        softWrap: softWrap,
      ),
    );
  }
}

class DieIcon extends StatelessWidget {
  final int sides;
  final double size;
  final Color? color;
  const DieIcon({super.key, required this.sides, this.size = 28, this.color});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _DiePainter(sides, color ?? SheetPalette.of(context).accent),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(size * .22),
          child: FittedBox(
            child: Text(
              '$sides',
              style: TextStyle(
                fontSize: size * .4,
                fontWeight: FontWeight.w800,
                color: color ?? SheetPalette.of(context).accent,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _DiePainter extends CustomPainter {
  final int sides;
  final Color color;
  _DiePainter(this.sides, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final points = <Offset>[];
    if (sides == 4) {
      points.addAll([
        Offset(w * .5, h * .05),
        Offset(w * .97, h * .91),
        Offset(w * .03, h * .91),
      ]);
    } else if (sides == 6) {
      points.addAll([
        Offset(w * .16, h * .1),
        Offset(w * .84, h * .1),
        Offset(w * .94, h * .23),
        Offset(w * .94, h * .8),
        Offset(w * .81, h * .94),
        Offset(w * .16, h * .94),
        Offset(w * .06, h * .8),
        Offset(w * .06, h * .23),
      ]);
    } else if (sides == 8) {
      points.addAll([
        Offset(w * .5, h * .02),
        Offset(w * .96, h * .5),
        Offset(w * .5, h * .98),
        Offset(w * .04, h * .5),
      ]);
    } else if (sides == 10) {
      points.addAll([
        Offset(w * .5, h * .02),
        Offset(w * .94, h * .3),
        Offset(w * .86, h * .76),
        Offset(w * .5, h * .98),
        Offset(w * .14, h * .76),
        Offset(w * .06, h * .3),
      ]);
    } else {
      final vertices = sides == 12 ? 5 : 6;
      for (var i = 0; i < vertices; i++) {
        final a = -math.pi / 2 + i * math.pi * 2 / vertices;
        points.add(
          Offset(
            w * .5 + math.cos(a) * w * .47,
            h * .5 + math.sin(a) * h * .47,
          ),
        );
      }
    }
    final outline = Path()..addPolygon(points, true);
    canvas.drawPath(outline, Paint()..color = color.withValues(alpha: .08));
    canvas.drawPath(
      outline,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
    final facet = Paint()
      ..color = color.withValues(alpha: .35)
      ..strokeWidth = .8;
    for (final p in points) {
      final target = Offset(
        w * .5 + (p.dx - w * .5) * .63,
        h * .5 + (p.dy - h * .5) * .63,
      );
      canvas.drawLine(p, target, facet);
    }
  }

  @override
  bool shouldRepaint(_DiePainter old) =>
      old.sides != sides || old.color != color;
}

/// A book-shaped checkbox with standard checkbox semantics and keyboard input.
class TomeCheckbox extends StatelessWidget {
  final bool checked;
  final String label;
  final ValueChanged<bool> onChanged;
  const TomeCheckbox({
    super.key,
    required this.checked,
    required this.label,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    checked: checked,
    onTap: () => onChanged(!checked),
    child: Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: InkWell(
        excludeFromSemantics: true,
        borderRadius: BorderRadius.circular(10),
        onTap: () => onChanged(!checked),
        child: SizedBox(
          width: 48,
          height: 52,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: checked ? 1 : 0),
            duration: const Duration(milliseconds: 180),
            builder: (context, fill, child) => CustomPaint(
              painter: _TomePainter(
                fill,
                Theme.of(context).colorScheme.primary,
                SheetPalette.of(context).background,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _TomePainter extends CustomPainter {
  final double fill;
  final Color color, background;
  _TomePainter(this.fill, this.color, this.background);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final book = Path()
      ..moveTo(w * .22, h * .18)
      ..lineTo(w * .72, h * .12)
      ..quadraticBezierTo(w * .81, h * .13, w * .81, h * .22)
      ..lineTo(w * .81, h * .76)
      ..lineTo(w * .28, h * .85)
      ..quadraticBezierTo(w * .16, h * .82, w * .16, h * .74)
      ..lineTo(w * .16, h * .29)
      ..quadraticBezierTo(w * .16, h * .2, w * .22, h * .18)
      ..close();
    canvas.drawPath(book, Paint()..color = color.withValues(alpha: .75 * fill));
    final pen = Paint()
      ..color = color.withValues(alpha: .55 + .45 * fill)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(book, pen);
    canvas.drawLine(Offset(w * .28, h * .2), Offset(w * .28, h * .73), pen);
    canvas.drawPath(
      Path()
        ..moveTo(w * .18, h * .75)
        ..quadraticBezierTo(w * .22, h * .7, w * .29, h * .74)
        ..lineTo(w * .81, h * .66),
      pen,
    );
    canvas.drawLine(
      Offset(w * .33, h * .77),
      Offset(w * .73, h * .7),
      pen..strokeWidth = .8,
    );
    final center = Offset(w * .53, h * .43), star = Path();
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4;
      final radius = (i.isEven ? .13 : .045) * w;
      final p =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();
    canvas.drawPath(
      star,
      Paint()
        ..color = Color.lerp(color, background, fill)!
        ..style = fill > .5 ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_TomePainter old) =>
      old.fill != fill || old.color != color || old.background != background;
}
