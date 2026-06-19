import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Seed colour — swap this one constant to re-theme the entire app.
// ---------------------------------------------------------------------------
const _seed = Color(0xFF3949AB); // Indigo 600 — strong but not aggressive

ThemeData get appTheme     => _build(Brightness.light);
ThemeData get appThemeDark => _build(Brightness.dark);

ThemeData _build(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final scheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: brightness,
    // Slightly warmer neutrals improve text readability over pure grey.
    dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
  );

  final base = isDark
      ? ThemeData.dark(useMaterial3: true)
      : ThemeData.light(useMaterial3: true);

  // ---------------------------------------------------------------------------
  // Text theme — Inter with intentional size/weight/height hierarchy
  // ---------------------------------------------------------------------------
  final baseText = GoogleFonts.interTextTheme(base.textTheme);
  final textTheme = baseText.copyWith(
    // --- Display ---
    displayLarge:  baseText.displayLarge!.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    displayMedium: baseText.displayMedium!.copyWith(fontWeight: FontWeight.w700),
    // --- Headline (screen titles) ---
    headlineLarge:  baseText.headlineLarge!.copyWith(fontWeight: FontWeight.w700),
    headlineMedium: baseText.headlineMedium!.copyWith(fontWeight: FontWeight.w600),
    headlineSmall:  baseText.headlineSmall!.copyWith(fontWeight: FontWeight.w600),
    // --- Title (card / section headers) ---
    titleLarge:  baseText.titleLarge!.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 18,
      height: 1.4,
    ),
    titleMedium: baseText.titleMedium!.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 15,
      height: 1.4,
    ),
    titleSmall: baseText.titleSmall!.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: 13,
    ),
    // --- Body (main readable text) ---
    bodyLarge:  baseText.bodyLarge!.copyWith(
      fontSize: 16,
      height: 1.55,
    ),
    bodyMedium: baseText.bodyMedium!.copyWith(
      fontSize: 14,
      height: 1.5,
    ),
    bodySmall: baseText.bodySmall!.copyWith(
      fontSize: 12,
      height: 1.45,
    ),
    // --- Label (buttons, chips, captions) ---
    labelLarge:  baseText.labelLarge!.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      letterSpacing: 0.1,
    ),
    labelMedium: baseText.labelMedium!.copyWith(
      fontSize: 12,
      letterSpacing: 0.3,
    ),
    labelSmall: baseText.labelSmall!.copyWith(
      fontSize: 11,
      letterSpacing: 0.4,
    ),
  );

  // ---------------------------------------------------------------------------
  // Component themes
  // ---------------------------------------------------------------------------
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: textTheme,

    // AppBar — flush with surface, clear title
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 2,
      titleTextStyle: textTheme.titleLarge!.copyWith(
        color: scheme.onSurface,
      ),
      centerTitle: false,
    ),

    // Cards — visible 1 px border, very slight tint
    cardTheme: CardThemeData(
      elevation: 0,
      color: isDark
          ? scheme.surfaceContainerLow
          : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: scheme.outlineVariant,
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
    ),

    // List tiles — breathing room
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: textTheme.bodyLarge,
      subtitleTextStyle: textTheme.bodyMedium!.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),

    // Divider — subtle
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),

    // Input fields — comfortable padding, clear focus state
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? scheme.surfaceContainerHigh
          : scheme.surfaceContainerLowest,
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.outlineVariant, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.primary, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.error, width: 2.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),

    // Filled buttons — standard radius, bold label
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),

    // Outlined buttons
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide(color: scheme.primary),
      ),
    ),

    // Text buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    // Chips — pill shape, readable label
    chipTheme: ChipThemeData(
      labelStyle: textTheme.labelMedium,
      side: BorderSide(color: scheme.outlineVariant),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),

    // BottomNavigationBar / NavigationBar
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelSmall!.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          size: 24,
        );
      }),
    ),

    // Floating action button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Snack bars — dark surface regardless of mode for contrast
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium!.copyWith(
        color: scheme.onInverseSurface,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
