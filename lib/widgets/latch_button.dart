import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../config/theme.dart';

enum ButtonStyleKind { primary, ghost }

/// The primary action. Pressing it squeezes it; while [busy] its label
/// becomes a pair of the keeper's eyes glancing about (the button keeps its
/// colour, so it reads as working, not refused); when [done] it shrinks to
/// a circle and draws a tick.
class LatchButton extends StatefulWidget {
  const LatchButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.done = false,
    this.icon,
  }) : kind = ButtonStyleKind.primary;

  const LatchButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  })  : kind = ButtonStyleKind.ghost,
        busy = false,
        done = false;

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool done;
  final IconData? icon;
  final ButtonStyleKind kind;

  @override
  State<LatchButton> createState() => _LatchButtonState();
}

class _LatchButtonState extends State<LatchButton>
    with TickerProviderStateMixin {
  late final _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 380),
  );
  late final _morph = AnimationController(vsync: this, duration: Motion.medium);
  late final _tick = AnimationController(vsync: this, duration: Motion.medium);

  @override
  void didUpdateWidget(LatchButton old) {
    super.didUpdateWidget(old);
    if (widget.done && !old.done) {
      HapticFeedback.mediumImpact();
      _morph.forward().then((_) {
        if (mounted) _tick.forward();
      });
    } else if (!widget.done && old.done) {
      _tick.value = 0;
      _morph.reverse();
    }
  }

  @override
  void dispose() {
    _press.dispose();
    _morph.dispose();
    _tick.dispose();
    super.dispose();
  }

  bool get _enabled =>
      widget.onPressed != null && !widget.busy && !widget.done;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primary = widget.kind == ButtonStyleKind.primary;
    final disabled = widget.onPressed == null;
    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => _press.forward() : null,
        onTapCancel: () => _press.reverse(),
        onTapUp: _enabled
            ? (_) {
                _press.reverse();
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: LayoutBuilder(builder: (context, box) {
          final full = box.maxWidth;
          return AnimatedBuilder(
            animation: Listenable.merge([_press, _morph]),
            builder: (context, _) {
              final m = Motion.settle.transform(_morph.value);
              final width = full - (full - Tokens.buttonHeight) * m;
              final pressScale = 1 - _press.value * 0.035;
              return Center(
                child: Transform.scale(
                  scale: pressScale,
                  child: Container(
                    width: width,
                    height: Tokens.buttonHeight,
                    decoration: BoxDecoration(
                      color: primary ? null : p.card.withValues(alpha: 0.6),
                      gradient: primary
                          ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: disabled
                                  ? [p.line, p.line]
                                  : [p.accentGlow, p.accent],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(
                          Tokens.buttonRadius + (Tokens.buttonHeight / 2 - Tokens.buttonRadius) * m),
                      border: primary
                          ? Border.all(
                              color: p.accentDeep.withValues(alpha: disabled ? 0 : 0.35))
                          : Border.all(color: p.line, width: 1.2),
                      boxShadow: primary && !disabled
                          ? [
                              BoxShadow(
                                color: p.accent.withValues(alpha: 0.38 - _press.value * 0.2),
                                blurRadius: 24 - _press.value * 10,
                                spreadRadius: -4,
                                offset: Offset(0, 12 - _press.value * 6),
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Tokens.buttonHeight / 2),
                      child: _content(context, p, primary, m),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _content(BuildContext context, Palette p, bool primary, double m) {
    final ink = primary ? p.onAccent : p.ink;
    if (m > 0.02) {
      return Center(
        child: AnimatedBuilder(
          animation: _tick,
          builder: (_, _) => CustomPaint(
            size: const Size(26, 26),
            painter: _TickPainter(_tick.value, ink),
          ),
        ),
      );
    }
    return AnimatedSwitcher(
      duration: Motion.short,
      switchInCurve: Motion.enter,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.35), end: Offset.zero)
              .animate(a),
          child: child,
        ),
      ),
      child: widget.busy
          ? _EyesLoader(key: const ValueKey('busy'), eye: p.eye, pupil: p.face)
          : Row(
              key: const ValueKey('label'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20, color: ink),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge!
                        .copyWith(color: widget.onPressed == null ? p.muted : ink),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TickPainter extends CustomPainter {
  _TickPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.54)
      ..lineTo(size.width * 0.42, size.height * 0.76)
      ..lineTo(size.width * 0.84, size.height * 0.28);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * Motion.settle.transform(t)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.t != t || old.color != color;
}

/// The keeper's eyes, glancing left and right and blinking: Latch's loader.
class _EyesLoader extends StatefulWidget {
  const _EyesLoader({super.key, required this.eye, required this.pupil});

  final Color eye, pupil;

  @override
  State<_EyesLoader> createState() => _EyesLoaderState();
}

class _EyesLoaderState extends State<_EyesLoader>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.loops(context)) {
      _c.repeat();
    } else {
      _c.value = 0.25;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Working',
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: const Size(46, 24),
          painter: _EyesPainter(_c.value, widget.eye, widget.pupil),
        ),
      ),
    );
  }
}

class _EyesPainter extends CustomPainter {
  _EyesPainter(this.t, this.eye, this.pupil);

  final double t;
  final Color eye, pupil;

  @override
  void paint(Canvas canvas, Size size) {
    // Look left, look right, then a blink at the end of each glance.
    final look = math.sin(t * math.pi * 2);
    final blinkPhase = (t * 2) % 1;
    final lid = blinkPhase > 0.9 ? math.sin((blinkPhase - 0.9) / 0.1 * math.pi) : 0.0;
    for (final cx in [size.width * 0.27, size.width * 0.73]) {
      final rect = Rect.fromCenter(
          center: Offset(cx, size.height / 2), width: 17, height: 20 * (1 - lid * 0.9));
      canvas.drawOval(rect, Paint()..color = eye);
      canvas.save();
      canvas.clipPath(Path()..addOval(rect));
      canvas.drawCircle(Offset(cx + look * 4, size.height / 2 + 1), 5.2,
          Paint()..color = pupil);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_EyesPainter old) => old.t != t;
}
