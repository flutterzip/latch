import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';

/// A checkbox whose tick draws itself, with a label that can hold links.
class CheckRow extends StatelessWidget {
  const CheckRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.child,
    this.error = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget child;

  /// Outlines the box in the error colour (asked to agree, did not).
  final bool error;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      checked: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<double>(
                duration: Motion.medium,
                curve: Motion.settle,
                tween: Tween(end: value ? 1 : 0),
                builder: (_, t, _) => Transform.scale(
                  scale: 1 + 0.12 * (t * (1 - t) * 4),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color.lerp(p.field, p.accent, t),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: error && !value
                            ? p.error
                            : Color.lerp(p.line, p.accentDeep, t)!,
                        width: 1.5,
                      ),
                    ),
                    child: CustomPaint(painter: _Tick(t, p.onAccent)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: error && !value ? p.error : p.inkSoft,
                      ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tick extends CustomPainter {
  _Tick(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final path = Path()
      ..moveTo(size.width * 0.24, size.height * 0.52)
      ..lineTo(size.width * 0.43, size.height * 0.7)
      ..lineTo(size.width * 0.77, size.height * 0.32);
    final m = path.computeMetrics().first;
    canvas.drawPath(
      m.extractPath(0, m.length * t.clamp(0.0, 1.0)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_Tick old) => old.t != t || old.color != color;
}
