import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../state/session.dart';

/// A small note with the demo values, tappable to fill them in. Hidden with
/// one switch in Demo settings so the app can be recorded clean.
class DemoHint extends ConsumerWidget {
  const DemoHint({super.key, required this.text, this.onUse, this.action = 'Use'});

  final String text;
  final VoidCallback? onUse;
  final String action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(demoSettingsProvider.select((s) => s.hints));
    final p = context.palette;
    return AnimatedSize(
      duration: Motion.short,
      curve: Motion.settle,
      child: !show
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Material(
                color: p.accentWash,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onUse,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 16, color: p.accentDeep),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            text,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(color: p.inkSoft),
                          ),
                        ),
                        if (onUse != null)
                          Text(
                            action,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(color: p.accentDeep, fontWeight: FontWeight.w700),
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
