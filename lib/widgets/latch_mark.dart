import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../config/palette.dart';

/// Latch's mark: a rounded door with a keyhole that lights up.
///
/// [draw] traces the outline (0 to 1) and [light] fills the keyhole and
/// warms the door, so the splash can build it from nothing. The app icon is
/// generated from the same geometry by `tool/make_icons.py`.
class LatchMark extends StatelessWidget {
  const LatchMark({super.key, this.size = 64, this.draw = 1, this.light = 1});

  final double size;
  final double draw;
  final double light;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _MarkPainter(
          draw: draw,
          light: light,
          door: p.accent,
          lit: p.accentGlow,
          deep: p.accentDeep,
          hole: p.face,
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({
    required this.draw,
    required this.light,
    required this.door,
    required this.lit,
    required this.deep,
    required this.hole,
  });

  final double draw, light;
  final Color door, lit, deep, hole;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.scale(s);
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(8, 8, 84, 84), const Radius.circular(30));

    if (light > 0) {
      canvas.drawRRect(
        body,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(20, 8),
            const Offset(80, 92),
            [lit.withValues(alpha: light), door.withValues(alpha: light), deep.withValues(alpha: light)],
            [0, 0.55, 1],
          ),
      );
      canvas.drawRRect(
        body.deflate(0.5),
        Paint()
          ..color = lit.withValues(alpha: 0.5 * light)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 14),
      );
    }

    final outline = Path()..addRRect(body);
    final m = outline.computeMetrics().first;
    canvas.drawPath(
      m.extractPath(0, m.length * draw.clamp(0.0, 1.0)),
      Paint()
        ..color = deep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // The keyhole grows from its centre as the light comes on.
    final k = Curves.easeOutBack.transform(light.clamp(0.0, 1.0));
    if (k > 0) {
      canvas.save();
      canvas.translate(50, 52);
      canvas.scale(k);
      canvas.translate(-50, -52);
      final keyhole = Path()
        ..addOval(Rect.fromCircle(center: const Offset(50, 42), radius: 11))
        ..moveTo(44, 46)
        ..lineTo(56, 46)
        ..lineTo(59.5, 70)
        ..quadraticBezierTo(50, 73, 40.5, 70)
        ..close();
      canvas.drawPath(keyhole, Paint()..color = hole);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.draw != draw || old.light != light || old.door != door;
}
