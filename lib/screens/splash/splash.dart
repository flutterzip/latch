import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/brand.dart';
import '../../config/motion.dart';
import '../../config/palette.dart';
import '../../config/timing.dart';
import '../../widgets/latch_mark.dart';

/// The first thing anyone sees: the mark draws itself, the keyhole lights,
/// the wordmark rises letter by letter, then the whole thing dissolves into
/// the first screen.
///
/// One controller, one timeline. [showing] goes false as it starts to
/// leave, so overlays and launch hooks can wait for it.
class Splash extends StatefulWidget {
  const Splash({super.key, required this.ready, required this.onGone});

  /// Resolves when the app behind is ready to be seen.
  final Future<void> ready;
  final VoidCallback onGone;

  static final showing = ValueNotifier<bool>(true);

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  late final _in = AnimationController(vsync: this, duration: AppTiming.splashIn);
  late final _out = AnimationController(vsync: this, duration: AppTiming.splashOut);
  bool _hapticDone = false;

  @override
  void initState() {
    super.initState();
    Splash.showing.value = true;
    _in.addListener(() {
      if (!_hapticDone && _in.value > 0.42) {
        _hapticDone = true;
        HapticFeedback.lightImpact();
      }
    });
    _run();
  }

  Future<void> _run() async {
    if (AppTiming.scale == 0) {
      await widget.ready;
      return _gone();
    }
    await Future.wait([_in.forward().orCancel.catchError((_) {}), widget.ready]);
    await AppTiming.wait(AppTiming.splashHold);
    if (!mounted) return;
    Splash.showing.value = false;
    await _out.forward().orCancel.catchError((_) {});
    _gone();
  }

  void _gone() {
    Splash.showing.value = false;
    if (mounted) widget.onGone();
  }

  @override
  void dispose() {
    _in.dispose();
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final reduced = Motion.reduced(context);
    return AnimatedBuilder(
      animation: Listenable.merge([_in, _out]),
      builder: (context, _) {
        final t = reduced ? 1.0 : _in.value;
        final out = Motion.exit.transform(_out.value);
        double phase(double a, double b) => Motion.enter.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
        return IgnorePointer(
          ignoring: _out.value > 0,
          child: Opacity(
            opacity: 1 - out,
            child: Material(
              color: p.paper,
              child: Center(
                child: Transform.scale(
                  scale: 1 + out * 0.08,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(0, (1 - phase(0.45, 0.7)) * 26),
                        child: LatchMark(
                          size: 92,
                          draw: phase(0.0, 0.42),
                          light: phase(0.36, 0.62),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _Wordmark(text: AppBrand.name, t: phase(0.45, 0.85), style: text.displaySmall!),
                      const SizedBox(height: 10),
                      Opacity(
                        opacity: phase(0.7, 1),
                        child: Text(AppBrand.tagline, style: text.bodyLarge),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Letters rising out of a clipped baseline, one after another.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.text, required this.t, required this.style});

  final String text;
  final double t;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final n = text.length;
    return ClipRect(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < n; i++)
            Builder(builder: (context) {
              final local = ((t * (n + 2) - i) / 3).clamp(0.0, 1.0);
              final e = Motion.spring.transform(local);
              return Opacity(
                opacity: local,
                child: Transform.translate(
                  offset: Offset(0, (1 - e) * 44),
                  child: Text(text[i], style: style.copyWith(fontSize: 44)),
                ),
              );
            }),
        ],
      ),
    );
  }
}
