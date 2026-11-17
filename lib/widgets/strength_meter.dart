import 'package:flutter/material.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import 'validators.dart';

/// Four segments that fill as a password gets longer, with a word for how
/// strong it is. Stepped in lightness of the one accent, never a traffic
/// light.
class StrengthMeter extends StatelessWidget {
  const StrengthMeter({super.key, required this.password});

  final String password;

  static const _words = [
    '',
    'Too short',
    'Could be stronger',
    'Good',
    'Strong',
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final score = Check.password(password);
    final ramp = [p.accentGlow, p.accent, p.accent, p.accentDeep];
    return AnimatedSize(
      duration: Motion.short,
      curve: Motion.settle,
      alignment: Alignment.topCenter,
      child: password.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: p.line,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        alignment: Alignment.centerLeft,
                        child: TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 320 + i * 60),
                          curve: Motion.settle,
                          tween: Tween(end: score > i ? 1 : 0),
                          builder: (_, t, _) => FractionallySizedBox(
                            widthFactor: t,
                            child: Container(
                              decoration: BoxDecoration(
                                color: score <= 1 ? p.error : ramp[i],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 116,
                    child: AnimatedSwitcher(
                      duration: Motion.short,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerRight,
                        children: [...previous, ?current],
                      ),
                      child: Text(
                        _words[score],
                        key: ValueKey(score),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          color: score <= 1 ? p.error : p.accentDeep,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
