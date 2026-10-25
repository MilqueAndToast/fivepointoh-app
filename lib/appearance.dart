import 'package:flutter/material.dart';

class AppearanceScope extends InheritedWidget {
  final bool dark;
  final Future<void> Function()? onToggle;
  const AppearanceScope({
    super.key,
    required this.dark,
    required this.onToggle,
    required super.child,
  });
  static AppearanceScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearanceScope>();
  @override
  bool updateShouldNotify(AppearanceScope oldWidget) =>
      dark != oldWidget.dark || onToggle != oldWidget.onToggle;
}

class AppearanceToggle extends StatelessWidget {
  final bool compact;
  const AppearanceToggle({super.key, this.compact = false});
  @override
  Widget build(BuildContext context) {
    final appearance = AppearanceScope.of(context);
    if (appearance == null) return const SizedBox.shrink();
    final label = appearance.dark ? 'Light Mode' : 'Dark Mode';
    Future<void> toggle() async {
      try {
        await appearance.onToggle?.call();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not save the appearance preference. Please try again.',
              ),
            ),
          );
        }
      }
    }

    final icon = Icon(
      appearance.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      size: 19,
    );
    return Semantics(
      toggled: appearance.dark,
      child: IconButton.outlined(
        key: const ValueKey('appearance-toggle'),
        tooltip: 'Switch To $label',
        onPressed: appearance.onToggle == null ? null : toggle,
        style: IconButton.styleFrom(
          fixedSize: const Size.square(44),
          minimumSize: const Size.square(44),
          maximumSize: const Size.square(44),
          padding: EdgeInsets.zero,
          alignment: Alignment.center,
          visualDensity: VisualDensity.standard,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        ),
        icon: icon,
      ),
    );
  }
}
