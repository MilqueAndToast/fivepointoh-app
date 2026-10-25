import 'sheet_palette.dart';
import 'package:flutter/material.dart';
import 'tabletop_widgets.dart';

class SpellDetails {
  final String name, body;
  final List<String> actions;
  final Set<String> components;
  final bool concentration;
  SpellDetails(
    this.name,
    this.body,
    this.actions,
    this.components,
    this.concentration,
  );
  static String normalized(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  static const fullNames = {
    'expeditretreat': 'Expeditious Retreat',
    'stoneskin': 'Stoneskin',
    'counterdispell': 'Counter and Dispel Magic',
  };
  factory SpellDetails.parse(
    String name,
    String note, {
    String actionHint = '',
    String? sourceName,
  }) {
    final lines = note.trim().split('\n');
    final canonical = fullNames[normalized(name)] ?? name;
    final first = lines.first.trim();
    final original = sourceName ?? name;
    final titles = {
      normalized(name),
      normalized(canonical),
      normalized(original),
      normalized(fullNames[normalized(original)] ?? original),
    };
    final hasTitle = first.isNotEmpty && titles.contains(normalized(first));
    final displayName = normalized(name) == normalized(original)
        ? canonical
        : name;
    if (hasTitle) lines.removeAt(0);
    final actions = <String>[];
    final components = <String>{};
    var concentration = false;
    // Read metadata only from the note header; prose can mention other spells
    // and casting requirements without defining this spell's requirements.
    for (var index = 0; index < lines.length; index++) {
      final header = lines[index].trim();
      if (header.isEmpty) break;
      if (header.length > 100) break;
      if (RegExp(r'\bsingle action\b', caseSensitive: false).hasMatch(header)) {
        actions.add('single');
      }
      if (RegExp(r'\bdouble action\b', caseSensitive: false).hasMatch(header)) {
        actions.add('double');
      }
      if (RegExp(r'\btriple action\b', caseSensitive: false).hasMatch(header)) {
        actions.add('triple');
      }
      if (RegExp(r'\breaction\b', caseSensitive: false).hasMatch(header)) {
        actions.add('reaction');
      }
      if (RegExp(r'\britual\b', caseSensitive: false).hasMatch(header)) {
        actions.add('ritual');
      }
      if (RegExp(
        r'^[VSM](?:\s*[,/]\s*[VSM])*$',
        caseSensitive: false,
      ).hasMatch(header)) {
        components.addAll(
          RegExp(
            '[VSM]',
            caseSensitive: false,
          ).allMatches(header).map((m) => m[0]!.toUpperCase()),
        );
        lines[index] = '';
      }
      final actionLine = RegExp(
        r'^(?:(?:Single|Double|Triple)\s+Action|Reaction|Ritual)(?:\s*(?:/|or)\s*(?:(?:Single|Double|Triple)\s+Action|Reaction|Ritual))*\s*\*?$',
        caseSensitive: false,
      );
      if (actionLine.hasMatch(header)) {
        lines[index] = '';
      }
      if (RegExp(r'\bconcentration\b', caseSensitive: false).hasMatch(header)) {
        concentration = true;
        final timing = header
            .replaceAll(
              RegExp(r'\bconcentration\b\s*[,;:]?\s*', caseSensitive: false),
              '',
            )
            .replaceAll(RegExp(r'^[\s,;:]+|[\s,;:]+$'), '')
            .trim();
        lines[index] = timing.isEmpty
            ? ''
            : '${timing[0].toUpperCase()}${timing.substring(1)}';
      }
    }
    if (!actions.any((a) => a != 'ritual')) {
      final count = RegExp('[♦◆]').allMatches(actionHint).length;
      if (count > 0) {
        actions.insert(
          0,
          count >= 3
              ? 'triple'
              : count == 2
              ? 'double'
              : 'single',
        );
      }
      if (actionHint.contains('↩')) actions.add('reaction');
    }
    return SpellDetails(
      displayName,
      lines.join('\n').replaceAll(RegExp(r'\n(?:[ \t]*\n){2,}'), '\n\n').trim(),
      actions.toSet().toList(),
      components,
      concentration,
    );
  }
}

class SpellCard extends StatefulWidget {
  final String name, note, actionHint, sourceName;
  final bool? expanded;
  final ValueChanged<bool>? onExpansionChanged;
  final Widget? editor;
  const SpellCard({
    super.key,
    required this.name,
    required this.note,
    this.actionHint = '',
    required this.sourceName,
    this.expanded,
    this.onExpansionChanged,
    this.editor,
  });
  @override
  State<SpellCard> createState() => _SpellCardState();
}

class _SpellCardState extends State<SpellCard> {
  final controller = ExpansibleController();
  @override
  void didUpdateWidget(covariant SpellCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded != null && oldWidget.expanded != widget.expanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.expanded!) {
          controller.expand();
        } else {
          controller.collapse();
        }
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spell = SpellDetails.parse(
      widget.name,
      widget.note,
      actionHint: widget.actionHint,
      sourceName: widget.sourceName,
    );
    return ExpansionTile(
      controller: controller,
      initiallyExpanded: widget.expanded ?? false,
      onExpansionChanged: widget.onExpansionChanged,
      tilePadding: const EdgeInsets.symmetric(vertical: 4),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: SheetPalette.of(context).accent,
      collapsedIconColor: SheetPalette.of(context).muted,
      title: LayoutBuilder(
        builder: (context, c) => Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: c.maxWidth),
              child: DiceText(
                spell.name,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: SheetPalette.of(context).accent,
                ),
              ),
            ),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final action in spell.actions) SpellBadge(kind: action),
                for (final component in spell.components)
                  SpellBadge(kind: component),
                if (spell.concentration)
                  const SpellBadge(kind: 'concentration'),
              ],
            ),
          ],
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child:
              widget.editor ??
              DiceText(
                spell.body.isEmpty
                    ? 'No effect note in the reference sheet.'
                    : spell.body,
                style: TextStyle(
                  color: SheetPalette.of(context).muted,
                  height: 1.4,
                ),
              ),
        ),
      ],
    );
  }
}

class SpellBadge extends StatelessWidget {
  final String kind;
  const SpellBadge({super.key, required this.kind});
  static Color colorFor(
    String kind, {
    SheetPalette palette = SheetPalette.light,
  }) => kind == 'concentration'
      ? palette.concentration
      : {'V', 'S', 'M'}.contains(kind)
      ? palette.teal
      : palette.accent;
  static const labels = {
    'single': 'Single Action',
    'double': 'Double Action',
    'triple': 'Triple Action',
    'reaction': 'Reaction',
    'ritual': 'Ritual',
    'V': 'Verbal',
    'S': 'Somatic',
    'M': 'Material',
    'concentration': 'Concentration',
  };
  static const icons = {
    'reaction': Icons.reply_rounded,
    'ritual': Icons.hourglass_bottom_rounded,
    'V': Icons.record_voice_over_outlined,
    'S': Icons.back_hand_outlined,
    'M': Icons.diamond_outlined,
    'concentration': Icons.center_focus_strong,
  };
  @override
  Widget build(BuildContext context) {
    final color = colorFor(kind, palette: SheetPalette.of(context));
    final diamonds = kind == 'single'
        ? 1
        : kind == 'double'
        ? 2
        : kind == 'triple'
        ? 3
        : 0;
    return Tooltip(
      message: labels[kind] ?? kind,
      child: Semantics(
        label: labels[kind] ?? kind,
        image: true,
        child: Container(
          width: diamonds > 1 ? 24 + diamonds * 9 : 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .07),
            border: Border.all(color: color.withValues(alpha: .3)),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: diamonds > 0
              ? CustomPaint(
                  size: Size(diamonds * 10.0 + 2, 18),
                  painter: _ActionPainter(diamonds, color),
                )
              : Icon(icons[kind], size: 18, color: color),
        ),
      ),
    );
  }
}

class _ActionPainter extends CustomPainter {
  final int count;
  final Color color;
  _ActionPainter(this.count, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < count; i++) {
      final x = 6 + i * 10.0;
      canvas.drawPath(
        Path()
          ..moveTo(x, 2)
          ..lineTo(x + 4, 9)
          ..lineTo(x, 16)
          ..lineTo(x - 4, 9)
          ..close(),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_ActionPainter old) =>
      old.count != count || old.color != color;
}

class SpellLegend extends StatelessWidget {
  const SpellLegend({super.key});
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 9,
    children: [
      for (final kind in [
        'single',
        'double',
        'reaction',
        'V',
        'S',
        'M',
        'concentration',
      ])
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpellBadge(kind: kind),
            const SizedBox(width: 5),
            Text(
              SpellBadge.labels[kind]!,
              style: TextStyle(
                fontSize: 11,
                color: SheetPalette.of(context).muted,
              ),
            ),
          ],
        ),
    ],
  );
}
