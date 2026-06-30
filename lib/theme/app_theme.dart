import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Atölye kimliği: mürekkep + keten + pirinç.
/// Terzi dünyasından gelen sıcak, butik bir palet. Standart Material
/// mavisinin yerine; dikiş (stitch) motifi imza öğesi.

/// Markaya özel renkler. `Theme.of(context).extension<AtelierColors>()!`
@immutable
class AtelierColors extends ThemeExtension<AtelierColors> {
  const AtelierColors({
    required this.canvas,
    required this.ink,
    required this.graphite,
    required this.brass,
    required this.brassSoft,
    required this.sage,
    required this.plum,
    required this.amber,
    required this.stitch,
  });

  /// Sıcak keten zemin (scaffold).
  final Color canvas;

  /// Sıcak siyaha yakın ana metin.
  final Color ink;

  /// Yumuşak gri ikincil metin.
  final Color graphite;

  /// Pirinç/bronz imza vurgusu.
  final Color brass;

  /// Açık pirinç dolgu (rozet/etiket arka planı).
  final Color brassSoft;

  /// Teslim / tahsil edildi (adaçayı yeşili).
  final Color sage;

  /// Prova (erik moru).
  final Color plum;

  /// Yaklaşan / acil (sıcak kehribar).
  final Color amber;

  /// Dikiş çizgisi rengi.
  final Color stitch;

  @override
  AtelierColors copyWith({
    Color? canvas,
    Color? ink,
    Color? graphite,
    Color? brass,
    Color? brassSoft,
    Color? sage,
    Color? plum,
    Color? amber,
    Color? stitch,
  }) {
    return AtelierColors(
      canvas: canvas ?? this.canvas,
      ink: ink ?? this.ink,
      graphite: graphite ?? this.graphite,
      brass: brass ?? this.brass,
      brassSoft: brassSoft ?? this.brassSoft,
      sage: sage ?? this.sage,
      plum: plum ?? this.plum,
      amber: amber ?? this.amber,
      stitch: stitch ?? this.stitch,
    );
  }

  @override
  AtelierColors lerp(ThemeExtension<AtelierColors>? other, double t) {
    if (other is! AtelierColors) return this;
    return AtelierColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      graphite: Color.lerp(graphite, other.graphite, t)!,
      brass: Color.lerp(brass, other.brass, t)!,
      brassSoft: Color.lerp(brassSoft, other.brassSoft, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      plum: Color.lerp(plum, other.plum, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      stitch: Color.lerp(stitch, other.stitch, t)!,
    );
  }

  static const light = AtelierColors(
    canvas: Color(0xFFF3EFE9),
    ink: Color(0xFF23201C),
    graphite: Color(0xFF7C766C),
    brass: Color(0xFF8C6A3A),
    brassSoft: Color(0xFFEFE4CF),
    sage: Color(0xFF5C7355),
    plum: Color(0xFF6E5078),
    amber: Color(0xFFB26B22),
    stitch: Color(0xFFB9AC97),
  );
}

/// Atölye temasını kurar.
ThemeData buildAtelierTheme() {
  const c = AtelierColors.light;
  const surface = Color(0xFFFBF9F5);

  final scheme = ColorScheme.fromSeed(
    seedColor: c.brass,
    brightness: Brightness.light,
  ).copyWith(
    primary: c.brass,
    onPrimary: Colors.white,
    primaryContainer: c.brassSoft,
    onPrimaryContainer: const Color(0xFF3D2E12),
    secondary: c.plum,
    secondaryContainer: const Color(0xFFE7E1D6),
    onSecondaryContainer: const Color(0xFF3A352C),
    surface: surface,
    onSurface: c.ink,
    onSurfaceVariant: c.graphite,
    outline: const Color(0xFF9C958A),
    outlineVariant: const Color(0xFFE0D9CD),
    surfaceContainerHighest: const Color(0xFFEAE4D8),
    error: const Color(0xFFB23A2E),
    onError: Colors.white,
    errorContainer: const Color(0xFFF6DDD6),
    onErrorContainer: const Color(0xFF5A1A12),
  );

  final baseText = GoogleFonts.manropeTextTheme().apply(
    bodyColor: c.ink,
    displayColor: c.ink,
  );

  // Başlıklar ve sayılar için karakterli serif (Fraunces).
  TextStyle display(double size, {FontWeight w = FontWeight.w600}) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: w,
        color: c.ink,
        height: 1.05,
      );

  final textTheme = baseText.copyWith(
    displayLarge: display(48),
    displayMedium: display(38),
    displaySmall: display(30),
    headlineMedium: display(26),
    headlineSmall: display(22),
    titleLarge: display(20, w: FontWeight.w600),
    titleMedium: GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: c.ink,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.canvas,
    textTheme: textTheme,
    extensions: const [c],
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: c.canvas,
      foregroundColor: c.ink,
      titleTextStyle: GoogleFonts.fraunces(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: c.ink,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      color: surface,
      shadowColor: const Color(0x14000000),
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      elevation: 0,
      height: 68,
      indicatorColor: c.brassSoft,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? c.brass : c.graphite,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected ? const Color(0xFF3D2E12) : c.graphite,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.brass, width: 1.5),
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(surface),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      side: WidgetStatePropertyAll(
        BorderSide(color: scheme.outlineVariant),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      hintStyle: WidgetStatePropertyAll(
        GoogleFonts.manrope(color: c.graphite, fontSize: 14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.brass,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.ink,
      foregroundColor: const Color(0xFFF6E9CF),
      elevation: 2,
      extendedTextStyle: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: GoogleFonts.fraunces(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: c.ink,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
  );
}
