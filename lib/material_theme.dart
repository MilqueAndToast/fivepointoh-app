import 'package:flutter/material.dart';
import 'sheet_palette.dart';

ThemeData ledgerMaterialTheme({required bool desktop, bool dark = false}) {
  final palette = dark ? SheetPalette.dark : SheetPalette.light;
  final colors =
      ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: dark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: palette.accent,
        primaryContainer: palette.primaryContainer,
        onPrimaryContainer: palette.text,
        secondaryContainer: palette.surfaceHigh,
        onSecondaryContainer: palette.text,
        onPrimary: palette.onAccent,
        secondary: palette.teal,
        onSecondary: palette.onAccent,
        surface: palette.background,
        onSurface: palette.text,
        onSurfaceVariant: palette.muted,
        surfaceContainerLowest: palette.background,
        surfaceContainerLow: palette.deep,
        surfaceContainer: palette.surface,
        surfaceContainerHigh: palette.surfaceHigh,
        surfaceContainerHighest: palette.surfaceHigh,
        outline: palette.muted,
        outlineVariant: palette.border,
      );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    fontFamily: 'LedgerSerif',
  );
  final density = desktop
      ? const VisualDensity(horizontal: -1, vertical: -1)
      : VisualDensity.standard;
  final buttons = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(0, desktop ? 36 : 44)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    visualDensity: density,
  );
  return base.copyWith(
    scaffoldBackgroundColor: palette.background,
    visualDensity: density,
    textTheme: base.textTheme.copyWith(
      bodyMedium: TextStyle(
        fontFamily: 'LedgerSerif',
        fontSize: 14,
        height: 1.45,
        color: palette.text,
      ),
      titleLarge: TextStyle(
        fontFamily: 'LedgerSerif',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        color: palette.text,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'LedgerSerif',
        fontSize: 38,
        fontWeight: FontWeight.w700,
        color: palette.text,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: palette.accent, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: buttons),
    outlinedButtonTheme: OutlinedButtonThemeData(style: buttons),
    textButtonTheme: TextButtonThemeData(style: buttons),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size.square(desktop ? 36 : 48)),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
        visualDensity: density,
        foregroundColor: WidgetStatePropertyAll(palette.accent),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      side: BorderSide(color: palette.muted, width: 1),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Colors.transparent,
      selectedColor: palette.primaryContainer,
      side: BorderSide(color: palette.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      labelStyle: TextStyle(
        fontFamily: 'LedgerSerif',
        fontSize: 12,
        color: palette.text,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    ),
    listTileTheme: ListTileThemeData(
      dense: true,
      minTileHeight: desktop ? 36 : 48,
      minVerticalPadding: 2,
      horizontalTitleGap: 12,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.deep,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    drawerTheme: DrawerThemeData(backgroundColor: palette.deep),
    dividerTheme: DividerThemeData(
      color: palette.border,
      thickness: .7,
      space: 1,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.background,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: palette.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: palette.border),
      ),
    ),
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 450),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
