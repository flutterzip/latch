import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';

/// A one-time code: one hidden field behind a row of boxes, so paste and
/// SMS autofill work and backspace never gets stuck between boxes.
///
/// Digits drop into their box, the next box glows with a blinking caret, a
/// wrong code shakes the row, and a right one fills every box in a wave.
class CodeInput extends StatefulWidget {
  const CodeInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.error = false,
    this.success = false,
    this.autofocus = true,
    this.focusNode,
  });

  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  /// Shakes the row and tints it. Set it after a wrong code.
  final bool error;

  /// Fills the boxes in a wave. Set it after a right code.
  final bool success;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<CodeInput> with TickerProviderStateMixin {
  late final _shake = AnimationController(vsync: this, duration: Motion.shake);
  late final _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
  late final _caret = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    _focus.addListener(_changed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.loops(context)) {
      _caret.repeat();
    } else {
      _caret.value = 0.25;
    }
  }

  @override
  void didUpdateWidget(CodeInput old) {
    super.didUpdateWidget(old);
    if (widget.error && !old.error) {
      HapticFeedback.heavyImpact();
      if (!Motion.reduced(context)) _shake.forward(from: 0);
    }
    if (widget.success && !old.success) {
      HapticFeedback.mediumImpact();
      _wave.forward(from: Motion.reduced(context) ? 1 : 0);
    }
    if (!widget.success && old.success) _wave.value = 0;
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _focus.removeListener(_changed);
    _ownFocus?.dispose();
    _shake.dispose();
    _wave.dispose();
    _caret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    return Semantics(
      label: 'Verification code, ${widget.length} digits',
      textField: true,
      child: GestureDetector(
        onTap: () => _focus.requestFocus(),
        child: Stack(
          children: [
            // The real field: invisible, under the boxes, takes the input.
            Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: widget.length,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  widget.onChanged?.call(v);
                  if (v.length == widget.length) widget.onCompleted?.call(v);
                },
              ),
            ),
            AnimatedBuilder(
              animation: Listenable.merge([_shake, _wave, _caret]),
              builder: (context, _) {
                final t = _shake.value;
                final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: Row(
                    children: [
                      for (var i = 0; i < widget.length; i++) ...[
                        if (i > 0) SizedBox(width: i == widget.length ~/ 2 ? 16 : 8),
                        Expanded(child: _box(context, i, code)),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(BuildContext context, int i, String code) {
    final p = context.palette;
    final digit = i < code.length ? code[i] : null;
    final active = _focus.hasFocus && i == code.length.clamp(0, widget.length - 1) && !widget.success;
    // The success wave reaches box i a little after box i - 1.
    final w = ((_wave.value * (widget.length + 3) - i) / 3).clamp(0.0, 1.0);
    final fill = Color.lerp(active ? p.card : p.field, p.accent, w)!;
    final border = widget.error
        ? p.error
        : Color.lerp(active ? p.accent : (digit != null ? p.accentDeep.withValues(alpha: 0.4) : p.line), p.accentDeep, w)!;
    return AspectRatio(
      aspectRatio: 0.82,
      child: Transform.translate(
        offset: Offset(0, -math.sin(w * math.pi) * 8),
        child: AnimatedContainer(
          duration: Motion.short,
          curve: Motion.settle,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: active || widget.error ? 1.8 : 1.2),
            boxShadow: [
              BoxShadow(
                color: p.accent.withValues(alpha: active ? 0.25 : 0),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: Motion.medium,
            switchInCurve: Motion.spring,
            transitionBuilder: (child, a) => ScaleTransition(
              scale: Tween(begin: 0.4, end: 1.0).animate(a),
              child: FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, -0.5), end: Offset.zero).animate(a),
                  child: child,
                ),
              ),
            ),
            child: digit != null
                ? Text(
                    digit,
                    key: ValueKey('$i$digit'),
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          color: Color.lerp(widget.error ? p.error : p.ink, p.onAccent, w),
                        ),
                  )
                : active
                    ? Opacity(
                        key: const ValueKey('caret'),
                        opacity: _caret.value < 0.5 ? 1 : 0,
                        child: Container(width: 2, height: 26, color: p.accentDeep),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),
      ),
    );
  }
}

/// "Resend code in 0:24", then a link once the wait is over.
class ResendTimer extends StatefulWidget {
  const ResendTimer({super.key, required this.onResend, this.wait = const Duration(seconds: 30)});

  final Future<void> Function() onResend;
  final Duration wait;

  @override
  State<ResendTimer> createState() => _ResendTimerState();
}

class _ResendTimerState extends State<ResendTimer> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.wait)..forward();
  bool _sending = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    await widget.onResend();
    if (!mounted) return;
    setState(() => _sending = false);
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final left = (widget.wait.inSeconds * (1 - _c.value)).ceil();
        final ready = _c.isCompleted && !_sending;
        return AnimatedSwitcher(
          duration: Motion.short,
          child: ready
              ? TextButton(
                  key: const ValueKey('ready'),
                  onPressed: _resend,
                  style: TextButton.styleFrom(foregroundColor: p.accentDeep),
                  child: Text('Resend code', style: text.labelMedium!.copyWith(color: p.accentDeep, fontWeight: FontWeight.w700)),
                )
              : Row(
                  key: const ValueKey('wait'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        value: _sending ? null : 1 - _c.value,
                        strokeWidth: 2.2,
                        color: p.accent,
                        backgroundColor: p.line,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _sending ? 'Sending a new code' : 'Resend code in 0:${left.toString().padLeft(2, '0')}',
                      style: text.bodySmall,
                    ),
                  ],
                ),
        );
      },
    );
  }
}
