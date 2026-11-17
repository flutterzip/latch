import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/motion.dart';
import '../config/palette.dart';

/// A ring of sparks and ribbons thrown out from behind the keeper when
/// something is finished. Only shades of the one accent, stepped by
/// lightness. Plays once on mount, or again whenever [play] changes.
class SparkBurst extends StatefulWidget {
  const SparkBurst({super.key, required this.child, this.play = 0});

  final Widget child;

  /// Change it to play again.
  final int play;

  @override
  State<SparkBurst> createState() => _SparkBurstState();
}

class _SparkBurstState extends State<SparkBurst> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  final _sparks = <_Spark>[];

  @override
  void initState() {
    super.initState();
    final rng = math.Random(11);
    for (var i = 0; i < 26; i++) {
      final a = (i / 26) * math.pi * 2 + rng.nextDouble() * 0.2;
      _sparks.add(_Spark(
        angle: a,
        distance: 0.75 + rng.nextDouble() * 0.6,
        size: 3 + rng.nextDouble() * 5,
        shade: rng.nextInt(3),
        ribbon: i.isEven,
        spin: rng.nextDouble() * 6 - 3,
        delay: rng.nextDouble() * 0.15,
      ));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Motion.reduced(context) && _c.value == 0) _c.forward();
  }

  @override
  void didUpdateWidget(SparkBurst old) {
    super.didUpdateWidget(old);
    if (widget.play != old.play && !Motion.reduced(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomPaint(
      painter: _BurstPainter(_c, _sparks, [p.accentGlow, p.accent, p.accentDeep]),
      child: widget.child,
    );
  }
}

class _Spark {
  _Spark({
    required this.angle,
    required this.distance,
    required this.size,
    required this.shade,
    required this.ribbon,
    required this.spin,
    required this.delay,
  });

  final double angle, distance, size, spin, delay;
  final int shade;
  final bool ribbon;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t, this.sparks, this.shades) : super(repaint: t);

  final Animation<double> t;
  final List<_Spark> sparks;
  final List<Color> shades;

  @override
  void paint(Canvas canvas, Size size) {
    if (t.value == 0 || t.value == 1) return;
    final c = size.center(Offset.zero);
    final reach = size.shortestSide * 0.62;
    for (final s in sparks) {
      final local = ((t.value - s.delay) / (1 - s.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final out = Curves.easeOutCubic.transform(local);
      final fall = local * local * 40;
      final pos = c + Offset(math.cos(s.angle), math.sin(s.angle)) * reach * s.distance * out + Offset(0, fall);
      final alpha = (1 - Curves.easeInQuad.transform(local)).clamp(0.0, 1.0);
      final paint = Paint()..color = shades[s.shade].withValues(alpha: alpha);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(s.spin * local * math.pi);
      if (s.ribbon) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s.size * 0.7, height: s.size * 2.2), const Radius.circular(2)),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, s.size / 2, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => false;
}
