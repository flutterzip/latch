import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';

/// A row of dots that fill as a passcode is typed. A wrong one shakes the
/// row; a right one makes the dots hop one after another.
class PasscodeDots extends StatefulWidget {
  const PasscodeDots({
    super.key,
    required this.filled,
    this.length = 4,
    this.error = false,
    this.success = false,
  });

  final int filled;
  final int length;
  final bool error;
  final bool success;

  @override
  State<PasscodeDots> createState() => _PasscodeDotsState();
}

class _PasscodeDotsState extends State<PasscodeDots> with TickerProviderStateMixin {
  late final _shake = AnimationController(vsync: this, duration: Motion.shake);
  late final _hop = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  @override
  void didUpdateWidget(PasscodeDots old) {
    super.didUpdateWidget(old);
    final reduced = Motion.reduced(context);
    if (widget.error && !old.error) {
      HapticFeedback.heavyImpact();
      if (!reduced) _shake.forward(from: 0);
    }
    if (widget.success && !old.success && !reduced) _hop.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: '${widget.filled} of ${widget.length} digits entered',
      child: AnimatedBuilder(
        animation: Listenable.merge([_shake, _hop]),
        builder: (context, _) {
          final t = _shake.value;
          return Transform.translate(
            offset: Offset(math.sin(t * math.pi * 6) * 12 * (1 - t), 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        -math.sin(((_hop.value * (widget.length + 2) - i) / 2).clamp(0.0, 1.0) * math.pi) * 12,
                      ),
                      child: _Dot(
                        filled: i < widget.filled,
                        color: widget.error ? p.error : p.accent,
                        ring: widget.error ? p.error : p.line,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.filled, required this.color, required this.ring});

  final bool filled;
  final Color color, ring;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ring, width: 2),
            ),
          ),
          AnimatedScale(
            scale: filled ? 1 : 0,
            duration: Motion.medium,
            curve: filled ? Motion.spring : Motion.exit,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 10)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A large numeric keypad. Bigger targets than the system keyboard, no
/// layout shift, and it cannot cover the dots.
class PasscodePad extends StatelessWidget {
  const PasscodePad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.onBiometric,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  /// Shows a Face ID key at the bottom left when set.
  final VoidCallback? onBiometric;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget row(List<Widget> keys) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: keys),
        );
    Widget digit(String d) => _Key(label: d, enabled: enabled, onTap: () => onDigit(d), child: Text(d));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row([digit('1'), digit('2'), digit('3')]),
        row([digit('4'), digit('5'), digit('6')]),
        row([digit('7'), digit('8'), digit('9')]),
        row([
          onBiometric == null
              ? const SizedBox(width: _Key.size)
              : _Key(
                  label: 'Use Face ID',
                  enabled: enabled,
                  plain: true,
                  onTap: onBiometric!,
                  child: Icon(Icons.face_retouching_natural_rounded, size: 28, color: p.accentDeep),
                ),
          digit('0'),
          _Key(
            label: 'Delete',
            enabled: enabled,
            plain: true,
            onTap: onDelete,
            child: Icon(Icons.backspace_outlined, size: 25, color: p.ink),
          ),
        ]),
      ],
    );
  }
}

class _Key extends StatefulWidget {
  const _Key({
    required this.label,
    required this.onTap,
    required this.child,
    this.enabled = true,
    this.plain = false,
  });

  static const size = 78.0;

  final String label;
  final VoidCallback onTap;
  final Widget child;
  final bool enabled;

  /// No disc behind it (delete, Face ID).
  final bool plain;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _down = false);
                HapticFeedback.lightImpact();
                widget.onTap();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.9 : 1,
          duration: Duration(milliseconds: _down ? 80 : 260),
          curve: _down ? Curves.easeOut : Motion.spring,
          child: AnimatedContainer(
            duration: Duration(milliseconds: _down ? 60 : 320),
            width: _Key.size,
            height: _Key.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.plain ? Colors.transparent : (_down ? p.accentWash : p.card.withValues(alpha: 0.7)),
              border: widget.plain ? null : Border.all(color: _down ? p.accent : p.line),
            ),
            alignment: Alignment.center,
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w600),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
