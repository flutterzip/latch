import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../config/theme.dart';

enum SocialProvider { apple, google }

/// Apple and Google, side by side.
///
/// These are the one sanctioned break from Latch's single accent: Apple's
/// button is black in light mode and white in dark, and Google's carries its
/// four-colour G. Their guidelines fix both, and restyled ones are rejected
/// in review. Height, radius, type and the busy state match the rest of the
/// form.
class SocialButtons extends StatelessWidget {
  const SocialButtons({
    super.key,
    required this.onPressed,
    this.pending,
    this.enabled = true,
  });

  final ValueChanged<SocialProvider> onPressed;

  /// The provider whose sign-in is under way; it shows a loader and every
  /// other button is disabled.
  final SocialProvider? pending;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _button(context, SocialProvider.apple)),
        const SizedBox(width: 12),
        Expanded(child: _button(context, SocialProvider.google)),
      ],
    );
  }

  Widget _button(BuildContext context, SocialProvider provider) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = context.palette;
    final apple = provider == SocialProvider.apple;
    final bg = apple ? (dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000)) : p.card;
    final fg = apple ? (dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF)) : p.ink;
    final busy = pending == provider;
    final active = enabled && pending == null;
    return _Pressable(
      onTap: active ? () => onPressed(provider) : null,
      label: apple ? 'Continue with Apple' : 'Continue with Google',
      child: AnimatedOpacity(
        duration: Motion.short,
        opacity: active || busy ? 1 : 0.55,
        child: Container(
          height: Tokens.buttonHeight,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(Tokens.buttonRadius),
            border: apple ? null : Border.all(color: p.line, width: 1.2),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: Motion.short,
              child: busy
                  ? SizedBox(
                      key: const ValueKey('busy'),
                      width: 22,
                      height: 22,
                      child: _Orbit(color: fg),
                    )
                  : Row(
                      key: const ValueKey('idle'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (apple)
                          Icon(Icons.apple, size: 23, color: fg)
                        else
                          const CustomPaint(size: Size(20, 20), painter: GoogleMark()),
                        const SizedBox(width: 10),
                        Text(
                          apple ? 'Apple' : 'Google',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .copyWith(color: fg, fontSize: 15.5),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap, required this.label});

  final Widget child;
  final VoidCallback? onTap;
  final String label;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      enabled: widget.onTap != null,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: widget.onTap == null
            ? null
            : (_) {
                setState(() => _down = false);
                HapticFeedback.lightImpact();
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: _down ? 0.965 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Motion.settle,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A small arc running round a circle.
class _Orbit extends StatefulWidget {
  const _Orbit({required this.color});

  final Color color;

  @override
  State<_Orbit> createState() => _OrbitState();
}

class _OrbitState extends State<_Orbit> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.loops(context)) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(painter: _OrbitPainter(_c.value, widget.color)),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r.deflate(1.5), 0, math.pi * 2, false,
        paint..color = color.withValues(alpha: 0.2));
    canvas.drawArc(r.deflate(1.5), t * math.pi * 2, math.pi * 0.6, false,
        paint..color = color);
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.t != t;
}

/// Google's G, drawn from four arcs and a crossbar.
class GoogleMark extends CustomPainter {
  const GoogleMark();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = s * 0.2;
    final rect = Rect.fromCircle(center: Offset(s / 2, s / 2), radius: s / 2 - stroke / 2);
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    const deg = math.pi / 180;
    canvas.drawArc(rect, -45 * deg, -90 * deg, false, arc(const Color(0xFFEA4335)));
    canvas.drawArc(rect, -135 * deg, -90 * deg, false, arc(const Color(0xFFFBBC05)));
    canvas.drawArc(rect, 135 * deg, -90 * deg, false, arc(const Color(0xFF34A853)));
    canvas.drawArc(rect, 45 * deg, -45 * deg, false, arc(const Color(0xFF4285F4)));
    canvas.drawRect(
      Rect.fromLTWH(s / 2, s / 2 - stroke / 2, s / 2 - stroke * 0.05, stroke),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(GoogleMark old) => false;
}

/// "or with email", between the social buttons and the form.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, this.label = 'or with email'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(child: Divider(color: p.line, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
        Expanded(child: Divider(color: p.line, height: 1)),
      ],
    );
  }
}
