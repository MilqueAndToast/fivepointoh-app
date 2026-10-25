import 'package:flutter/material.dart';
import 'sheet_palette.dart';
import 'tabletop_widgets.dart';

/// An explicit save keeps drafts separate from live character revisions.
class InlineText extends StatefulWidget {
  final String text, label;
  final String? displayText;
  final Future<void> Function(String) onSave;
  final ValueChanged<bool> onEditingChanged;
  const InlineText({
    super.key,
    required this.text,
    required this.label,
    this.displayText,
    required this.onSave,
    required this.onEditingChanged,
  });
  @override
  State<InlineText> createState() => _InlineTextState();
}

class _InlineTextState extends State<InlineText> {
  late final controller = TextEditingController(text: widget.text);
  bool editing = false, busy = false;
  String? error;
  @override
  void didUpdateWidget(InlineText old) {
    super.didUpdateWidget(old);
    if (!editing && old.text != widget.text) controller.text = widget.text;
  }

  @override
  void dispose() {
    widget.onEditingChanged(false);
    controller.dispose();
    super.dispose();
  }

  void start() {
    controller.text = widget.text;
    setState(() => editing = true);
    widget.onEditingChanged(true);
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.onSave(controller.text);
      if (mounted) {
        setState(() => editing = false);
        widget.onEditingChanged(false);
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => editing
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              enabled: !busy,
              minLines: 2,
              maxLines: null,
              maxLength: 12000,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: widget.label,
                counterText: '',
                errorText: error,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: busy ? null : save,
                  child: Text(busy ? 'Saving…' : 'Save'),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () {
                          setState(() {
                            editing = false;
                            error = null;
                          });
                          widget.onEditingChanged(false);
                        },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        )
      : Semantics(
          label: 'Edit ${widget.label}',
          button: true,
          child: SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: start,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: DiceText(
                  (widget.displayText ?? widget.text).trim().isEmpty
                      ? 'Add ${widget.label.toLowerCase()}…'
                      : (widget.displayText ?? widget.text),
                  style: TextStyle(
                    color: SheetPalette.of(context).text,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        );
}
