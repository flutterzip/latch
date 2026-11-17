import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Every colour in Latch is defined in this file.
//
// To re-skin the app, edit [Palette.light] and [Palette.dark] below. Every
// screen, the keeper, the backdrop, the fields, the code boxes and the
// passcode pad read their colours from here through `context.palette`.
// Nothing else in lib/ hard-codes a UI colour.
//
// One thing is deliberately not here: the Apple and Google sign-in buttons
// (lib/widgets/social_buttons.dart), whose colours are fixed by their brand
// guidelines.
//
// The system: warm paper, warm ink and exactly one accent (lamplight amber).
// Ink is never pure black and paper is never pure white.
// ---------------------------------------------------------------------------

@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.paper,
    required this.card,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.line,
    required this.field,
    required this.accent,
    required this.accentDeep,
    required this.accentGlow,
    required this.onAccent,
    required this.accentWash,
    required this.error,
    required this.eye,
    required this.face,
    required this.shadow,
    required this.scrim,
  });

  /// The page ground.
  final Color paper;

  /// Raised surfaces: the form card, sheets, the keypad keys.
  final Color card;

  /// Headlines, field text, the keeper's pupils.
  final Color ink;

  /// Body copy.
  final Color inkSoft;

  /// Hints, captions, inactive icons.
  final Color muted;

  /// Hairlines and resting field borders.
  final Color line;

  /// The fill of a field at rest.
  final Color field;

  /// The one accent: the primary button, focus, the keeper's body.
  final Color accent;

  /// The shaded side of the keeper and the pressed button.
  final Color accentDeep;

  /// The lit side of the keeper and the highlight of the backdrop lamps.
  final Color accentGlow;

  /// Type and icons on top of [accent].
  final Color onAccent;

  /// A pale tint of the accent for selected states and notices.
  final Color accentWash;

  /// Errors stay in the family: a deeper, redder neighbour of the accent.
  final Color error;

  /// The whites of the keeper's eyes.
  final Color eye;

  /// The keeper's pupils and mouth. Dark in both modes: it is drawn on the
  /// amber body, not on the page.
  final Color face;

  /// Shadows under raised surfaces.
  final Color shadow;

  /// Behind sheets.
  final Color scrim;

  static const light = Palette(
    paper: Color(0xFFFBF6EE),
    card: Color(0xFFFFFBF5),
    ink: Color(0xFF1F1A14),
    inkSoft: Color(0xFF4F463B),
    muted: Color(0xFF8E8374),
    line: Color(0xFFE8DECF),
    field: Color(0xFFF5EDE1),
    accent: Color(0xFFF29A33),
    accentDeep: Color(0xFFD47414),
    accentGlow: Color(0xFFFFC77A),
    onAccent: Color(0xFF2A1705),
    accentWash: Color(0xFFFCEAD2),
    error: Color(0xFFC9472B),
    eye: Color(0xFFFFFAF2),
    face: Color(0xFF231708),
    shadow: Color(0x2E6B4A1F),
    scrim: Color(0x661F1A14),
  );

  static const dark = Palette(
    paper: Color(0xFF14110D),
    card: Color(0xFF1E1A15),
    ink: Color(0xFFF7EFE3),
    inkSoft: Color(0xFFD0C5B5),
    muted: Color(0xFF908574),
    line: Color(0xFF2E2821),
    field: Color(0xFF231E18),
    accent: Color(0xFFF5A548),
    accentDeep: Color(0xFFCB6F14),
    accentGlow: Color(0xFFFFCB82),
    onAccent: Color(0xFF2A1705),
    accentWash: Color(0xFF3A2915),
    error: Color(0xFFF0805F),
    eye: Color(0xFFFFF8EC),
    face: Color(0xFF231708),
    shadow: Color(0x66000000),
    scrim: Color(0x99000000),
  );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      paper: c(paper, other.paper),
      card: c(card, other.card),
      ink: c(ink, other.ink),
      inkSoft: c(inkSoft, other.inkSoft),
      muted: c(muted, other.muted),
      line: c(line, other.line),
      field: c(field, other.field),
      accent: c(accent, other.accent),
      accentDeep: c(accentDeep, other.accentDeep),
      accentGlow: c(accentGlow, other.accentGlow),
      onAccent: c(onAccent, other.onAccent),
      accentWash: c(accentWash, other.accentWash),
      error: c(error, other.error),
      eye: c(eye, other.eye),
      face: c(face, other.face),
      shadow: c(shadow, other.shadow),
      scrim: c(scrim, other.scrim),
    );
  }
}

extension PaletteContext on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>()!;
}
