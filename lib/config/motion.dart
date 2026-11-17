import 'package:flutter/widgets.dart';

/// How things move. How long the app *waits* is a different question and
/// lives in `AppTiming`.
abstract final class Motion {
  static const quick = Duration(milliseconds: 160);
  static const short = Duration(milliseconds: 240);
  static const medium = Duration(milliseconds: 380);
  static const long = Duration(milliseconds: 600);

  /// A screen's sections rising in, from one controller sliced by intervals.
  static const entrance = Duration(milliseconds: 1000);

  /// One screen handing over to the next (the keeper flies between them).
  static const route = Duration(milliseconds: 620);

  /// A field or a row of code boxes shaking off a wrong answer.
  static const shake = Duration(milliseconds: 520);

  /// The keeper's reactions.
  static const blink = Duration(milliseconds: 170);
  static const headShake = Duration(milliseconds: 720);
  static const hop = Duration(milliseconds: 620);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const settle = Curves.easeOutQuart;
  static const spring = Curves.easeOutBack;

  /// How quickly the keeper's gaze and paws chase their targets (per second).
  /// Higher is snappier. Frame-rate independent.
  static const gazeFollow = 11.0;
  static const pawFollow = 9.0;
  static const moodFollow = 6.0;

  /// Ambient loops (the backdrop lamps, the keeper breathing and blinking)
  /// run only when this is true. Tests switch it off so `pumpAndSettle`
  /// can settle.
  static bool ambient = true;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static bool loops(BuildContext context) => ambient && !reduced(context);
}
