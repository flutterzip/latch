/// Every deliberate wait in the app, in one place. A demo whose actions
/// finish in one frame reads as fake, and a loading state nobody sees can
/// not be judged.
///
/// `--dart-define=timingScale=0` skips every wait, the splash included, for
/// automation and screenshot runs.
abstract final class AppTiming {
  static double scale =
      double.tryParse(const String.fromEnvironment('timingScale')) ?? 1.0;

  // Splash phases.
  static Duration get splashIn => _s(1700);
  static Duration get splashHold => _s(500);
  static Duration get splashOut => _s(650);

  // Simulated network.
  static Duration get signIn => _s(1500);
  static Duration get signUp => _s(1600);
  static Duration get socialSignIn => _s(1200);
  static Duration get sendCode => _s(1100);
  static Duration get verifyCode => _s(1000);
  static Duration get resetPassword => _s(1200);
  static Duration get savePasscode => _s(700);

  /// How long the button holds its tick before the next screen arrives.
  static Duration get successBeat => _s(650);

  /// Before "Resend code" can be pressed again.
  static const resendAfter = Duration(seconds: 30);

  static Duration _s(int ms) =>
      Duration(microseconds: (ms * 1000 * scale).round());

  static Future<void> wait(Duration d) =>
      d == Duration.zero ? Future.value() : Future.delayed(d);

  /// Runs [work] but never resolves sooner than [d], so a loader never
  /// flashes for a single frame.
  static Future<T> atLeast<T>(Duration d, Future<T> work) async {
    final results = await Future.wait<Object?>([work, wait(d)]);
    return results.first as T;
  }
}
