import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

/// Everything that can move on the keeper, at one instant.
class KeeperPose {
  double gazeX = 0, gazeY = 0;

  /// 0 paws at rest, 1 paws over the eyes.
  double cover = 0;

  /// 0 both paws up, 1 the left paw lowered to see through.
  double peek = 0;

  double mood = 0.35;

  /// Eyelids, 0 open to 1 shut (blinks).
  double lid = 0;

  /// 0 normal eyes, 1 happy arcs.
  double happy = 0;

  /// Sideways head offset while shaking, in design units.
  double shake = 0;

  /// Height of a hop, in design units, and the squash on landing.
  double hop = 0;
  double squash = 0;

  /// The right paw raised to wave (0..1) and its swing (-1..1).
  double wave = 0;
  double swing = 0;

  /// Breathing, -1..1.
  double breathe = 0;

  /// How far the antenna lags behind the head, in design units.
  double sway = 0;
}

/// Paints the keeper on a 200 x 200 design canvas, scaled to fit.
///
/// Every part is a parameter of [KeeperPose], so one drawing serves the
/// splash, every auth header and the success screen.
class KeeperPainter extends CustomPainter {
  KeeperPainter({
    required this.pose,
    required this.body,
    required this.bodyLit,
    required this.bodyDeep,
    required this.eye,
    required this.ink,
    required this.shadow,
    super.repaint,
  });

  final KeeperPose pose;
  final Color body, bodyLit, bodyDeep, eye, ink, shadow;

  static const design = 200.0;

  @override
  void paint(Canvas canvas, Size size) {
    final k = math.min(size.width, size.height) / design;
    canvas.save();
    canvas.translate(
        (size.width - design * k) / 2, (size.height - design * k) / 2);
    canvas.scale(k);

    final p = pose;
    _ground(canvas);

    // The body stretches on take-off, squashes on landing and breathes.
    final sy = 1 + p.breathe * 0.012 - p.squash * 0.10 + (p.hop > 0 ? 0.04 : 0);
    final sx = 1 - p.breathe * 0.006 + p.squash * 0.08;
    canvas.save();
    canvas.translate(100 + p.shake * 0.35, 186 - p.hop);
    canvas.rotate(p.shake * 0.006);
    canvas.scale(sx, sy);
    canvas.translate(-100, -186);

    _antenna(canvas);
    _body(canvas);

    final face = Offset(p.gazeX * 9 + p.shake, p.gazeY * 6);
    _blush(canvas, face);
    _eyes(canvas, face);
    _mouth(canvas, face);
    _paws(canvas, face);

    canvas.restore();
    canvas.restore();
  }

  // ---------------------------------------------------------------- parts

  static Path bodyPath() => Path()
    ..moveTo(100, 40)
    ..cubicTo(146, 40, 174, 76, 174, 120)
    ..cubicTo(174, 162, 143, 186, 100, 186)
    ..cubicTo(57, 186, 26, 162, 26, 120)
    ..cubicTo(26, 76, 54, 40, 100, 40)
    ..close();

  void _ground(Canvas canvas) {
    final lift = (pose.hop / 30).clamp(0.0, 1.0);
    final w = 116 * (1 - lift * 0.35);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 190), width: w, height: 14),
      Paint()
        ..color = shadow.withValues(alpha: shadow.a * (1 - lift * 0.5))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _antenna(Canvas canvas) {
    final tip = Offset(100 + pose.sway + pose.gazeX * 4, 16 - pose.hop * 0.05);
    final stem = Path()
      ..moveTo(100, 44)
      ..quadraticBezierTo(100 + pose.sway * 0.2, 28, tip.dx, tip.dy + 6);
    canvas.drawPath(
      stem,
      Paint()
        ..color = bodyDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      tip,
      8,
      Paint()
        ..shader = ui.Gradient.radial(
            tip.translate(-2.5, -2.5), 9, [bodyLit, body, bodyDeep],
            [0, 0.6, 1]),
    );
  }

  void _body(Canvas canvas) {
    final path = bodyPath();
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.radial(
          const Offset(76, 74),
          140,
          [bodyLit, body, bodyDeep],
          [0.0, 0.45, 1.0],
        ),
    );
    // Rim light along the lower right, and a soft specular on the crown.
    canvas.save();
    canvas.clipPath(path);
    canvas.drawCircle(
      const Offset(150, 165),
      70,
      Paint()
        ..color = bodyLit.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.restore();
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(74, 66), width: 34, height: 18),
      Paint()
        ..color = eye.withValues(alpha: 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  void _blush(Canvas canvas, Offset face) {
    final paint = Paint()
      ..color = bodyDeep.withValues(alpha: 0.18 + pose.mood * 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (final x in const [64.0, 136.0]) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(x, 130) + face * 0.8, width: 22, height: 11),
        paint,
      );
    }
  }

  void _eyes(Canvas canvas, Offset face) {
    final open = (1 - pose.happy).clamp(0.0, 1.0);
    final rx = 15.5;
    final ry = 17.5 + pose.mood * 2;
    for (final side in const [-1.0, 1.0]) {
      final c = Offset(100 + side * 22, 106) + face;
      if (open > 0.01) {
        final eyeRect = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
        canvas.saveLayer(eyeRect.inflate(2), Paint()..color = Color.fromRGBO(0, 0, 0, open));
        canvas.drawOval(eyeRect, Paint()..color = eye);
        canvas.save();
        canvas.clipPath(Path()..addOval(eyeRect));
        final pupil = c + Offset(pose.gazeX * 6.5, pose.gazeY * 7);
        canvas.drawCircle(pupil, 8.8, Paint()..color = ink);
        canvas.drawCircle(pupil + const Offset(-2.8, -3), 2.7,
            Paint()..color = eye);
        canvas.drawCircle(pupil + const Offset(2.6, 2.8), 1.1,
            Paint()..color = eye.withValues(alpha: 0.7));
        // The lid comes down from the top in the body's colour.
        final lid = pose.lid.clamp(0.0, 1.0);
        if (lid > 0) {
          final edge = eyeRect.top + eyeRect.height * lid;
          canvas.drawRect(
            Rect.fromLTRB(eyeRect.left - 2, eyeRect.top - 2,
                eyeRect.right + 2, edge),
            Paint()..color = body,
          );
          canvas.drawLine(
            Offset(eyeRect.left, edge),
            Offset(eyeRect.right, edge),
            Paint()
              ..color = bodyDeep
              ..strokeWidth = 2.4,
          );
        }
        canvas.restore();
        canvas.restore();
      }
      if (pose.happy > 0.01) {
        final arc = Path()
          ..moveTo(c.dx - 11, c.dy + 4)
          ..quadraticBezierTo(c.dx, c.dy - 12, c.dx + 11, c.dy + 4);
        canvas.drawPath(
          arc,
          Paint()
            ..color = ink.withValues(alpha: pose.happy.clamp(0.0, 1.0))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _mouth(Canvas canvas, Offset face) {
    final c = const Offset(100, 138) + face * 0.85;
    // Glum (-1) to grinning (1); a shake turns the corners down.
    final smile = (pose.mood * 2 - 0.3 - pose.shake.abs() * 0.12)
        .clamp(-1.0, 1.0);
    final open = (pose.happy + (pose.mood - 0.8).clamp(0.0, 0.2) * 4)
        .clamp(0.0, 1.0);
    final w = 10 + pose.mood * 5 + pose.happy * 3;
    if (open > 0.2) {
      final mouth = Path()
        ..moveTo(c.dx - w, c.dy - 1)
        ..quadraticBezierTo(c.dx, c.dy + 3, c.dx + w, c.dy - 1)
        ..cubicTo(c.dx + w * 0.8, c.dy + 6 + open * 14, c.dx - w * 0.8,
            c.dy + 6 + open * 14, c.dx - w, c.dy - 1)
        ..close();
      canvas.drawPath(mouth, Paint()..color = ink);
      canvas.save();
      canvas.clipPath(mouth);
      canvas.drawCircle(Offset(c.dx, c.dy + 6 + open * 12), 8 + open * 3,
          Paint()..color = bodyDeep);
      canvas.restore();
    } else {
      final curve = Path()
        ..moveTo(c.dx - w, c.dy)
        ..quadraticBezierTo(c.dx, c.dy + smile * 10, c.dx + w, c.dy);
      canvas.drawPath(
        curve,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paws(Canvas canvas, Offset face) {
    final cover = pose.cover.clamp(0.0, 1.0);
    for (final side in const [-1.0, 1.0]) {
      final rest = Offset(100 + side * 52, 168);
      final eyeSpot = Offset(100 + side * 21, 108) + face;
      var t = Curves.easeInOutCubic.transform(cover);
      var target = eyeSpot;
      // The viewer's left paw slides down to peek over its fingers.
      if (side < 0) target = target.translate(-4, pose.peek * 27);
      // Paws travel out and up around the body, not through the face.
      final mid = Offset(100 + side * 74, 130);
      var at = _quad(rest, mid, target, t);
      var angle = side * (0.35 - t * 0.75);

      // The right paw can wave instead (only when not covering).
      if (side > 0 && pose.wave > 0.01 && t < 0.5) {
        final w = Curves.easeOutBack.transform(pose.wave.clamp(0.0, 1.0));
        at = Offset.lerp(at, const Offset(168, 92), w)!;
        angle = ui.lerpDouble(angle, -0.9 + pose.swing * 0.45, w)!;
      }
      _paw(canvas, at, angle, 1 + t * 0.22);
    }
  }

  void _paw(Canvas canvas, Offset at, double angle, double scale) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    canvas.scale(scale);
    final r = Rect.fromCenter(center: Offset.zero, width: 42, height: 33);
    canvas.drawOval(
      r.shift(const Offset(0, 3)),
      Paint()
        ..color = shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawOval(
      r,
      Paint()
        ..shader = ui.Gradient.radial(
            const Offset(-6, -7), 26, [bodyLit, body, bodyDeep], [0, 0.55, 1]),
    );
    final finger = Paint()
      ..color = bodyDeep.withValues(alpha: 0.75)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (final dx in const [-6.0, 0.0, 6.0]) {
      canvas.drawLine(Offset(dx, -13), Offset(dx * 1.05, -6.5), finger);
    }
    canvas.restore();
  }

  static Offset _quad(Offset a, Offset b, Offset c, double t) {
    final u = 1 - t;
    return a * (u * u) + b * (2 * u * t) + c * (t * t);
  }

  @override
  bool shouldRepaint(KeeperPainter old) =>
      old.body != body ||
      old.bodyLit != bodyLit ||
      old.bodyDeep != bodyDeep ||
      old.eye != eye ||
      old.ink != ink ||
      old.pose != pose;
}
