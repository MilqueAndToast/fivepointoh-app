import 'sheet_palette.dart';
import 'package:flutter/material.dart';
import 'attack_icons.dart';
import 'tabletop_widgets.dart';

class AttackEntry {
  final int row;
  final String name, variety, damageType, damage, range, critical, ammo;
  final List<String> rolls;
  const AttackEntry({
    required this.row,
    required this.name,
    required this.variety,
    required this.damageType,
    required this.damage,
    required this.range,
    required this.critical,
    required this.ammo,
    required this.rolls,
  });
}

class CombatView extends StatefulWidget {
  final List<AttackEntry> attacks;
  final ValueChanged<int> onEdit;
  final Future<void> Function(int row, String value, bool damage) onAssign;
  const CombatView({
    super.key,
    required this.attacks,
    required this.onEdit,
    required this.onAssign,
  });
  @override
  State<CombatView> createState() => _CombatViewState();
}

class _CombatViewState extends State<CombatView> {
  int? selected;
  bool busy = false;
  String? error;
  Future<void> assign(AttackEntry attack, String? value, bool damage) async {
    if (value == null || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.onAssign(attack.row, value, damage);
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attacks.isEmpty) {
      return const Text('No attacks have been added.');
    }
    final attack = widget.attacks.firstWhere(
      (a) => a.row == selected,
      orElse: () => widget.attacks.first,
    );
    final variety = attackVarieties.contains(attack.variety)
        ? attack.variety
        : 'Unassigned';
    final type = canonicalDamage(attack.damageType);
    final types = {'Bash', 'Slash', 'Pierce', if (type.isNotEmpty) type};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('attack-selector-${attack.row}'),
                initialValue: attack.row,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Selected Attack'),
                items: [
                  for (final entry in widget.attacks)
                    DropdownMenuItem(
                      value: entry.row,
                      child: Row(
                        children: [
                          AttackGlyph(kind: entry.variety, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                onChanged: busy
                    ? null
                    : (value) => setState(() {
                        selected = value;
                        error = null;
                      }),
              ),
            ),
            IconButton(
              tooltip: 'Edit Attack',
              onPressed: busy ? null : () => widget.onEdit(attack.row),
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'ATTACK ROLLS · FIRST / SECOND / THIRD',
          style: TextStyle(
            fontSize: 10,
            color: SheetPalette.of(context).muted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final roll in attack.rolls)
              Chip(
                label: DiceText(
                  roll,
                  style: TextStyle(
                    color: sheetValueColor(roll, SheetPalette.of(context)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconMenu(
                  key: ValueKey('attack-variety-${attack.row}-$variety'),
                  kind: variety,
                  options: attackVarieties,
                  damage: false,
                  onSelected: (value) => assign(attack, value, false),
                ),
                _iconMenu(
                  key: ValueKey('damage-type-${attack.row}-$type'),
                  kind: type.isEmpty ? 'Unassigned' : type,
                  options: types.toList(),
                  damage: true,
                  onSelected: (value) => assign(attack, value, true),
                ),
              ],
            ),
            DiceText(
              attack.damage,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: sheetValueColor(attack.damage, SheetPalette.of(context)),
              ),
            ),
            Text(
              '•  ${attack.range} ft  •  Crit ${attack.critical}',
              style: TextStyle(
                color: SheetPalette.of(context).aqua,
                fontSize: 12,
              ),
            ),
            if (attack.ammo.isNotEmpty)
              Text(
                'Ammo ${attack.ammo}',
                style: TextStyle(
                  color: sheetValueColor(attack.ammo, SheetPalette.of(context)),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        if (busy)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Saving…'),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error!,
              style: TextStyle(color: SheetPalette.of(context).accent),
            ),
          ),
      ],
    );
  }

  Widget _iconMenu({
    required Key key,
    required String kind,
    required List<String> options,
    required bool damage,
    required ValueChanged<String> onSelected,
  }) {
    return PopupMenuButton<String>(
      key: key,
      enabled: !busy,
      initialValue: kind,
      tooltip: damage ? 'Damage Type: $kind' : 'Attack Icon: $kind',
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem(
            value: option,
            child: SizedBox(width: 220, child: _option(option, damage)),
          ),
      ],
      child: SizedBox.square(
        dimension: 44,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: SheetPalette.of(context).border.withValues(alpha: .65),
                width: .6,
              ),
            ),
          ),
          child: Center(
            child: AttackGlyph(kind: kind, damage: damage, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _option(String kind, bool damage) => Row(
    children: [
      AttackGlyph(kind: kind, damage: damage, size: 24),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          kind == 'Bash'
              ? 'Bashing'
              : kind == 'Slash'
              ? 'Slashing'
              : kind == 'Pierce'
              ? 'Piercing'
              : kind,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
