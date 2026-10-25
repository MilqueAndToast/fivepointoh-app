import 'sheet_palette.dart';
import 'equipment_figure.dart';
import 'package:flutter/material.dart';
import 'tabletop_widgets.dart';

class EquipmentSlot {
  final int id;
  final String label, item, description;
  const EquipmentSlot({
    required this.id,
    required this.label,
    required this.item,
    required this.description,
  });
  bool get equipped => item.trim().isNotEmpty;
  String get displayLabel => id == 14
      ? 'Ring I'
      : id == 15
      ? 'Ring II'
      : id == 16
      ? 'Legs'
      : label;
}

class EquipmentView extends StatefulWidget {
  final List<EquipmentSlot> slots;
  final String query;
  final ValueChanged<int> onEdit;
  const EquipmentView({
    super.key,
    required this.slots,
    required this.onEdit,
    this.query = '',
  });
  @override
  State<EquipmentView> createState() => _EquipmentViewState();
}

class _EquipmentViewState extends State<EquipmentView> {
  SheetPalette get palette => SheetPalette.of(context);
  int selected = 4;
  bool matches(EquipmentSlot slot) =>
      widget.query.isEmpty ||
      '${slot.label} ${slot.displayLabel} ${slot.item} ${slot.description}'
          .toLowerCase()
          .contains(widget.query.toLowerCase());
  @override
  Widget build(BuildContext context) {
    final matching = widget.slots.where(matches).toList();
    final chosen = widget.slots.firstWhere(
      (s) => s.id == selected,
      orElse: () => widget.slots.first,
    );
    final slot = matches(chosen) || matching.isEmpty ? chosen : matching.first;
    final count = widget.slots.where((s) => s.equipped).length;
    final diagram = _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Equipment Map',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$count / ${widget.slots.length} Equipped',
                style: TextStyle(color: palette.text, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select any part of the figure or a slot label.',
            style: TextStyle(color: palette.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  // A medium-width map still has room for both label gutters.
                  // Reserve the phone layout for genuinely narrow maps, even
                  // when the inventory detail panel is beside the diagram.
                  final narrow = width < 520;
                  final touchLabels = narrow && width >= 300;
                  final labelWidth = width < 740 ? 82.0 : 110.0;
                  final gap = width < 740 ? 16.0 : 28.0;
                  final available = width - 2 * (labelWidth + gap);
                  final bodyWidth = narrow
                      ? (width - 24).clamp(
                          0.0,
                          EquipmentFigure.width / EquipmentFigure.height * 640,
                        )
                      : available.clamp(0.0, 520.0);
                  final mapHeight = narrow
                      ? bodyWidth /
                            EquipmentFigure.width *
                            EquipmentFigure.height
                      : 640.0;
                  // Use a single scale on both axes; the label gutters must
                  // never squeeze the body into a tall, narrow silhouette.
                  final scale = (bodyWidth / EquipmentFigure.width).clamp(
                    0.0,
                    mapHeight / EquipmentFigure.height,
                  );
                  final bodyRect = Rect.fromLTWH(
                    (width - EquipmentFigure.width * scale) / 2 +
                        (touchLabels ? 16 : 0),
                    0,
                    EquipmentFigure.width * scale,
                    EquipmentFigure.height * scale,
                  );
                  final transform = Matrix4.identity()
                    ..translateByDouble(
                      bodyRect.left - EquipmentFigure.left * scale,
                      0,
                      0,
                      1,
                    )
                    ..scaleByDouble(
                      bodyRect.width / EquipmentFigure.width,
                      bodyRect.height / EquipmentFigure.height,
                      1,
                      1,
                    );
                  final figure = SizedBox(
                    height: mapHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            key: const ValueKey('equipment-body'),
                            painter: _BodyPainter(
                              widget.slots,
                              slot.id,
                              matching.map((s) => s.id).toSet(),
                              bodyRect,
                              labelWidth,
                              showLeaders: !narrow,
                              touchLabels: touchLabels,
                              palette: palette,
                            ),
                          ),
                        ),
                        for (final region in _regions)
                          _segment(
                            region,
                            region.path.transform(transform.storage),
                            slot.id,
                          ),
                        if (touchLabels)
                          for (final entry in _touchLabelRects(
                            width,
                            bodyRect,
                          ).entries)
                            Positioned.fromRect(
                              rect: entry.value,
                              child: _slotLabel(
                                _regions.firstWhere((r) => r.id == entry.key),
                                widget.slots.firstWhere(
                                  (s) => s.id == entry.key,
                                ),
                                slot.id,
                                onFigure: true,
                              ),
                            ),
                        if (!narrow)
                          for (final region in _regions)
                            Positioned(
                              left: region.right ? width - labelWidth : 0,
                              top: region.labelY,
                              width: labelWidth,
                              height: 45,
                              child: _slotLabel(
                                region,
                                widget.slots.firstWhere(
                                  (s) => s.id == region.id,
                                ),
                                slot.id,
                              ),
                            ),
                      ],
                    ),
                  );
                  if (!narrow) return figure;
                  return Column(
                    children: [
                      figure,
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final region in _regions)
                            if (!touchLabels ||
                                !_smallSlots.contains(region.id))
                              SizedBox(
                                width: (width - 10) / 3,
                                height: 45,
                                child: _slotLabel(
                                  region,
                                  widget.slots.firstWhere(
                                    (s) => s.id == region.id,
                                  ),
                                  slot.id,
                                ),
                              ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _legend('Equipped', palette.text, true),
              _legend('Empty', palette.muted, false),
              _legend('Selected', palette.accent, false),
            ],
          ),
        ],
      ),
    );
    final detail = _panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SLOT DETAILS',
            style: TextStyle(
              color: palette.muted,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                slot.equipped ? Icons.auto_awesome : Icons.crop_free,
                color: slot.equipped ? palette.text : palette.muted,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                slot.displayLabel,
                style: TextStyle(color: palette.accent, fontSize: 17),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DiceText(
            slot.equipped ? slot.item : 'Empty Slot',
            style: const TextStyle(fontSize: 24, height: 1.2),
          ),
          const SizedBox(height: 10),
          Divider(color: palette.border),
          const SizedBox(height: 10),
          if (!slot.equipped)
            Text(
              'No item is equipped here. Its outline is muted on your equipment map.',
              style: TextStyle(color: palette.muted, height: 1.4),
            )
          else
            DiceText(
              slot.description.trim().isEmpty
                  ? 'No item description has been added yet.'
                  : slot.description,
              style: TextStyle(color: palette.text, height: 1.4),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => widget.onEdit(slot.id),
            icon: Icon(
              slot.equipped ? Icons.edit_outlined : Icons.add,
              size: 18,
            ),
            label: Text(slot.equipped ? 'Edit Item' : 'Equip Item'),
          ),
          if (widget.query.isNotEmpty && matching.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                'No equipment matches your search.',
                style: TextStyle(color: palette.accent),
              ),
            ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth >= 1040
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: diagram),
                const SizedBox(width: 14),
                Expanded(flex: 2, child: detail),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [diagram, const SizedBox(height: 18), detail],
            ),
    );
  }

  Widget _segment(_BodyRegion region, Path shape, int current) {
    final bounds = shape.getBounds();
    final local = shape.shift(-bounds.topLeft);
    final slot = widget.slots.firstWhere((s) => s.id == region.id);
    void select() => setState(() => selected = region.id);
    return Positioned.fromRect(
      rect: bounds,
      child: ClipPath(
        key: ValueKey('equipment-body-slot-${region.id}'),
        clipper: _SegmentClipper(local),
        child: Semantics(
          label: '${slot.displayLabel} Body Segment',
          button: true,
          selected: current == slot.id,
          onTap: select,
          excludeSemantics: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: select,
              excludeFromSemantics: true,
              hoverColor: palette.accent.withValues(alpha: .16),
              splashColor: palette.accent.withValues(alpha: .25),
            ),
          ),
        ),
      ),
    );
  }

  Widget _slotLabel(
    _BodyRegion region,
    EquipmentSlot slot,
    int current, {
    bool onFigure = false,
  }) {
    final active = current == slot.id;
    final dim = !matches(slot);
    final color = active
        ? palette.accent
        : slot.equipped
        ? palette.text
        : palette.muted;
    return Semantics(
      selected: active,
      child: TextButton(
        key: ValueKey('equipment-slot-${slot.id}'),
        onPressed: () => setState(() => selected = slot.id),
        style: TextButton.styleFrom(
          foregroundColor: color.withValues(alpha: dim ? .35 : 1),
          backgroundColor: active
              ? color.withValues(alpha: .09)
              : onFigure
              ? palette.deep
              : Colors.transparent,
          minimumSize: const Size(0, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
            side: BorderSide(
              color: active
                  ? color.withValues(alpha: .5)
                  : onFigure
                  ? palette.border.withValues(alpha: .65)
                  : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: onFigure
              ? MainAxisAlignment.center
              : region.right
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                slot.displayLabel,
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!onFigure) ...[
              const SizedBox(width: 5),
              Icon(
                slot.equipped ? Icons.circle : Icons.circle_outlined,
                size: 6,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _panel(Widget child) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: palette.border, width: .8)),
    ),
    child: child,
  );
  Widget _legend(String label, Color color, bool filled) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: .4) : null,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 11, color: palette.muted)),
    ],
  );
}

class _SegmentClipper extends CustomClipper<Path> {
  final Path shape;
  _SegmentClipper(this.shape);
  @override
  Path getClip(Size size) => shape;
  @override
  bool shouldReclip(_SegmentClipper old) => old.shape != shape;
}

const _smallSlots = {5, 6, 8, 14, 15};

// Dedicated touch-sized controls stay beside the face and fingers. Enlarging
// their invisible body targets alone would take taps intended for nearby slots.
Map<int, Rect> _touchLabelRects(double width, Rect bodyRect) {
  final scale = bodyRect.height / EquipmentFigure.height;
  return {
    5: const Rect.fromLTWH(4, 20, 80, 44),
    6: const Rect.fromLTWH(4, 68, 80, 44),
    8: const Rect.fromLTWH(4, 116, 80, 44),
    14: Rect.fromLTWH(4, 708 * scale + 32, 64, 44),
    15: Rect.fromLTWH(width - 68, 708 * scale + 32, 64, 44),
  };
}

class _BodyRegion {
  final int id;
  final Path path;
  final Offset anchor;
  final bool right;
  final double labelY;
  _BodyRegion(this.id, this.path, this.anchor, this.right, this.labelY);
}

// Equipment selection follows the character's asymmetric pose.
final _regions = <_BodyRegion>[
  _BodyRegion(4, EquipmentFigure.hood, const Offset(566, 70), false, 16),
  _BodyRegion(5, EquipmentFigure.band, const Offset(541, 148), false, 64),
  _BodyRegion(6, EquipmentFigure.eye, const Offset(547, 181), false, 112),
  _BodyRegion(7, EquipmentFigure.shoulders, const Offset(703, 316), true, 156),
  _BodyRegion(8, EquipmentFigure.neck, const Offset(578, 282), false, 166),
  _BodyRegion(9, EquipmentFigure.chest, const Offset(585, 405), true, 224),
  _BodyRegion(10, EquipmentFigure.belt, const Offset(659, 511), true, 286),
  _BodyRegion(11, EquipmentFigure.wrists, const Offset(362, 572), false, 308),
  _BodyRegion(12, EquipmentFigure.hands, const Offset(360, 673), false, 366),
  _BodyRegion(13, EquipmentFigure.feet, const Offset(348, 1205), false, 566),
  _BodyRegion(16, EquipmentFigure.legs, const Offset(675, 875), true, 500),
  _BodyRegion(14, EquipmentFigure.leftRing, const Offset(369, 708), false, 424),
  _BodyRegion(15, EquipmentFigure.rightRing, const Offset(798, 700), true, 424),
];

class _BodyPainter extends CustomPainter {
  final List<EquipmentSlot> slots;
  final int selected;
  final Set<int> matching;
  final Rect bodyRect;
  final double labelWidth;
  final bool showLeaders, touchLabels;
  final SheetPalette palette;
  _BodyPainter(
    this.slots,
    this.selected,
    this.matching,
    this.bodyRect,
    this.labelWidth, {
    this.showLeaders = true,
    this.touchLabels = false,
    required this.palette,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final sx = bodyRect.width / EquipmentFigure.width,
        sy = bodyRect.height / EquipmentFigure.height;
    canvas.save();
    canvas.translate(bodyRect.left - EquipmentFigure.left * sx, bodyRect.top);
    canvas.scale(sx, sy);
    final outline = Paint()
      ..color = palette.muted.withValues(alpha: .65)
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.05 / sx;
    canvas.drawPath(EquipmentFigure.silhouette, outline);
    for (final region in _regions) {
      final slot = slots.firstWhere((s) => s.id == region.id);
      final active = selected == region.id;
      final dim = !matching.contains(region.id);
      final color = active ? palette.accent : palette.text;
      if (slot.equipped || active) {
        canvas.drawPath(
          region.path,
          Paint()
            ..color = color.withValues(
              alpha: dim
                  ? .015
                  : active
                  ? .16
                  : .045,
            ),
        );
      }
      if (active) {
        canvas.drawPath(
          region.path,
          Paint()
            ..color = color.withValues(alpha: dim ? .3 : 1)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4 / sx,
        );
      }
    }
    final seams = Paint()
      ..color = palette.text.withValues(alpha: .65)
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..strokeWidth = .85 / sx;
    canvas.drawPath(EquipmentFigure.seams, seams);
    canvas.drawPath(EquipmentFigure.buckle, seams);
    canvas.restore();

    if (!showLeaders && !touchLabels) return;
    // Leader lines are visual only; label and body hit regions never occupy the gutters.
    final callouts = touchLabels
        ? _touchLabelRects(size.width, bodyRect)
        : <int, Rect>{};
    for (final r in _regions) {
      if (!showLeaders && !_smallSlots.contains(r.id)) continue;
      final slot = slots.firstWhere((s) => s.id == r.id);
      final dim = !matching.contains(r.id);
      final color = selected == r.id
          ? palette.accent
          : slot.equipped
          ? palette.text
          : palette.muted;
      final anchor = Offset(
        bodyRect.left + (r.anchor.dx - EquipmentFigure.left) * sx,
        r.anchor.dy * sy,
      );
      final callout = callouts[r.id];
      final end = callout != null
          ? Offset(
              r.id == 15 ? callout.left - 6 : callout.right + 6,
              callout.center.dy,
            )
          : Offset(
              r.right ? size.width - labelWidth - 8 : labelWidth + 8,
              r.labelY + 22,
            );
      canvas.drawPath(
        Path()
          ..moveTo(anchor.dx, anchor.dy)
          ..lineTo((anchor.dx + end.dx) / 2, end.dy)
          ..lineTo(end.dx, end.dy),
        Paint()
          ..color = color.withValues(alpha: dim ? .1 : .3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
      canvas.drawCircle(
        anchor,
        1.8,
        Paint()..color = color.withValues(alpha: dim ? .2 : .8),
      );
    }
  }

  @override
  bool shouldRepaint(_BodyPainter old) => true;
}
