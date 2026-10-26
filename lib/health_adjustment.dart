import 'package:flutter/material.dart';

class HealthAdjustment extends StatefulWidget {
  final Future<void> Function(num amount) onApply;
  final ValueChanged<bool> onEditingChanged;
  const HealthAdjustment({
    super.key,
    required this.onApply,
    required this.onEditingChanged,
  });

  @override
  State<HealthAdjustment> createState() => _HealthAdjustmentState();
}

class _HealthAdjustmentState extends State<HealthAdjustment> {
  final controller = TextEditingController();
  bool busy = false;
  String? error;

  Future<void> apply() async {
    if (busy) return;
    final amount = num.tryParse(controller.text.trim());
    if (amount == null || !amount.isFinite) {
      setState(() => error = 'Enter a valid number.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.onApply(amount);
      if (!mounted) return;
      controller.clear();
      widget.onEditingChanged(false);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    widget.onEditingChanged(false);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    key: const ValueKey('health-adjustment-input'),
    controller: controller,
    enabled: !busy,
    keyboardType: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    textInputAction: TextInputAction.done,
    onChanged: (value) {
      widget.onEditingChanged(value.isNotEmpty);
      if (error != null) setState(() => error = null);
    },
    onSubmitted: (_) => apply(),
    decoration: InputDecoration(
      labelText: 'Damage / healing',
      hintText: 'e.g. 10 or -5',
      helperText: busy
          ? 'Applying…'
          : 'Damage + / healing -\nEnter to apply',
      helperMaxLines: 2,
      errorText: error,
      errorMaxLines: 3,
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    ),
  );
}
