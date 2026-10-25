import 'package:flutter/material.dart';
import 'sheet_engine.dart';
import 'sheet_palette.dart';

/// Always-editable fields, with an explicit save and cancel for the whole section.
class DirectEditor extends StatefulWidget {
  final String name;
  final Map<String, dynamic> values;
  final Set<String> numbers, integers;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final ValueChanged<bool> onEditingChanged;
  final Widget Function(BuildContext, DirectEditorState) builder;
  const DirectEditor({
    super.key,
    required this.name,
    required this.values,
    this.numbers = const {},
    this.integers = const {},
    required this.onSave,
    required this.onEditingChanged,
    required this.builder,
  });
  @override
  State<DirectEditor> createState() => DirectEditorState();
}

class DirectEditorState extends State<DirectEditor> {
  final controllers = <String, TextEditingController>{};
  final labels = <String, String>{};
  bool busy = false, acceptSavedValues = false;
  String? error;
  bool get dirty => widget.values.keys.any(
    (id) => controllers[id]!.text != SheetEngine.text(widget.values[id]),
  );
  @override
  void initState() {
    super.initState();
    for (final entry in widget.values.entries) {
      controllers[entry.key] = TextEditingController(
        text: SheetEngine.text(entry.value),
      );
    }
  }

  @override
  void didUpdateWidget(DirectEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final entry in widget.values.entries) {
      final controller = controllers[entry.key];
      if (controller == null) {
        controllers[entry.key] = TextEditingController(
          text: SheetEngine.text(entry.value),
        );
      } else if (acceptSavedValues ||
          controller.text == SheetEngine.text(oldWidget.values[entry.key])) {
        controller.text = SheetEngine.text(entry.value);
      }
    }
    acceptSavedValues = false;
  }

  @override
  void dispose() {
    widget.onEditingChanged(false);
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget field(
    String id,
    String label, {
    String hint = '—',
    TextAlign align = TextAlign.start,
    int maxLines = 1,
    TextStyle? style,
  }) {
    labels[id] = label;
    final numeric = widget.numbers.contains(id) || widget.integers.contains(id);
    return Semantics(
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: TextField(
          key: ValueKey('direct-$id'),
          controller: controllers[id],
          enabled: !busy,
          textAlign: align,
          minLines: 1,
          maxLines: maxLines,
          keyboardType: numeric
              ? TextInputType.numberWithOptions(
                  decimal: !widget.integers.contains(id),
                )
              : TextInputType.text,
          textInputAction: TextInputAction.done,
          style:
              style ??
              TextStyle(color: SheetPalette.of(context).text, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: SheetPalette.of(context).muted),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: SheetPalette.of(context).accent),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 12,
            ),
          ),
          onChanged: (_) {
            setState(() => error = null);
            widget.onEditingChanged(dirty);
          },
          onSubmitted: (_) {
            if (dirty && !busy) save();
          },
        ),
      ),
    );
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final changes = <String, dynamic>{};
      for (final id in widget.values.keys) {
        final text = controllers[id]!.text;
        if (text == SheetEngine.text(widget.values[id])) {
          continue;
        }
        dynamic value = text;
        if (widget.numbers.contains(id) || widget.integers.contains(id)) {
          if (text.trim().isEmpty) {
            value = widget.integers.contains(id) ? 0 : null;
          } else {
            final number = num.tryParse(text.trim());
            if (number == null ||
                !number.isFinite ||
                number < 0 ||
                (widget.integers.contains(id) &&
                    number != number.roundToDouble())) {
              throw FormatException(
                '${labels[id]} must be a nonnegative ${widget.integers.contains(id) ? 'whole number' : 'number'}.',
              );
            }
            value = number;
          }
        }
        changes[id] = value;
      }
      if (changes.isNotEmpty) await widget.onSave(changes);
      if (mounted) {
        acceptSavedValues = true;
        widget.onEditingChanged(false);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e
              .toString()
              .replaceFirst('FormatException: ', '')
              .replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      widget.builder(context, this),
      if (dirty || busy || error != null) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton(
              key: ValueKey('save-${widget.name.toLowerCase()}'),
              onPressed: busy ? null : save,
              child: Text(busy ? 'Saving…' : 'Save ${widget.name}'),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () {
                      for (final id in widget.values.keys) {
                        controllers[id]!.text = SheetEngine.text(
                          widget.values[id],
                        );
                      }
                      setState(() => error = null);
                      widget.onEditingChanged(false);
                    },
              child: const Text('Cancel'),
            ),
            Text(
              'Unsaved Changes',
              style: TextStyle(
                fontSize: 11,
                color: SheetPalette.of(context).muted,
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
    ],
  );
}
