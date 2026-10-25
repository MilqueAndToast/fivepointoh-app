import 'package:flutter/material.dart';
import 'sheet_palette.dart';

class ParchmentNotes extends StatefulWidget {
  final String text;
  final Future<void> Function(String) onSave;
  final ValueChanged<bool> onEditingChanged;
  const ParchmentNotes({
    super.key,
    required this.text,
    required this.onSave,
    required this.onEditingChanged,
  });
  @override
  State<ParchmentNotes> createState() => _ParchmentNotesState();
}

class _ParchmentNotesState extends State<ParchmentNotes> {
  late final controller = TextEditingController(text: widget.text);
  bool dirty = false, busy = false;
  String? error;
  @override
  void didUpdateWidget(ParchmentNotes old) {
    super.didUpdateWidget(old);
    if (!dirty && old.text != widget.text) controller.text = widget.text;
  }

  @override
  void dispose() {
    widget.onEditingChanged(false);
    controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.onSave(controller.text);
      if (mounted) {
        setState(() => dirty = false);
        widget.onEditingChanged(false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: SheetPalette.of(context).border, width: .8),
      ),
    ),
    child: CustomPaint(
      painter: _ParchmentPainter(SheetPalette.of(context).border),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: SheetPalette.of(context).accent),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Quick Notes',
                    style: TextStyle(
                      fontFamily: 'LedgerSerif',
                      fontSize: 22,
                      color: SheetPalette.of(context).text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('quick-notes-input'),
              controller: controller,
              enabled: !busy,
              minLines: 6,
              maxLines: 14,
              maxLength: 12000,
              keyboardType: TextInputType.multiline,
              style: TextStyle(
                color: SheetPalette.of(context).text,
                fontFamily: 'LedgerSerif',
                fontStyle: FontStyle.italic,
                height: 1.6,
                fontSize: 15,
              ),
              cursorColor: SheetPalette.of(context).accent,
              decoration: InputDecoration(
                labelText: 'Adventure Notes',
                labelStyle: TextStyle(color: SheetPalette.of(context).accent),
                hintText: 'Scrawl your discoveries, reminders, and plans…',
                hintStyle: TextStyle(color: SheetPalette.of(context).muted),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                counterText: '',
              ),
              onChanged: (_) {
                setState(() {
                  dirty = controller.text != widget.text;
                  error = null;
                });
                widget.onEditingChanged(dirty);
              },
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  key: const ValueKey('save-quick-notes'),
                  style: FilledButton.styleFrom(
                    backgroundColor: SheetPalette.of(context).accent,
                    foregroundColor: SheetPalette.of(context).onAccent,
                    disabledBackgroundColor: SheetPalette.of(
                      context,
                    ).surfaceHigh,
                    disabledForegroundColor: SheetPalette.of(context).muted,
                  ),
                  onPressed: dirty && !busy ? save : null,
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(busy ? 'Saving…' : 'Save Notes'),
                ),
                if (dirty)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: SheetPalette.of(context).text,
                    ),
                    onPressed: busy
                        ? null
                        : () {
                            controller.text = widget.text;
                            setState(() {
                              dirty = false;
                              error = null;
                            });
                            widget.onEditingChanged(false);
                          },
                    child: const Text('Cancel'),
                  ),
                Text(
                  dirty ? 'Unsaved Changes' : 'Notes Saved',
                  style: TextStyle(
                    fontSize: 11,
                    color: SheetPalette.of(context).accent,
                  ),
                ),
              ],
            ),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
  );
}

class _ParchmentPainter extends CustomPainter {
  final Color rule;
  _ParchmentPainter(this.rule);
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = rule.withValues(alpha: .22)
      ..strokeWidth = .7;
    for (var y = 70.0; y < size.height - 35; y += 24) {
      canvas.drawLine(Offset(12, y), Offset(size.width - 12, y), pen);
    }
  }

  @override
  bool shouldRepaint(_ParchmentPainter old) => old.rule != rule;
}
