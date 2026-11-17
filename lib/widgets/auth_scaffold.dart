import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../config/theme.dart';

/// The frame every auth screen shares: a back button, the keeper in the
/// header (it flies between screens as a Hero and shrinks while the
/// keyboard is up so it stays in view), and a frosted card holding the
/// title and the form.
///
/// ```dart
/// AuthScaffold(
///   keeper: Keeper(controller: keeper),
///   title: 'Welcome back',
///   subtitle: 'Sign in to pick up where you left off.',
///   children: [ ... ],
/// )
/// ```
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.keeper,
    required this.title,
    required this.children,
    this.subtitle,
    this.footer,
    this.onBack,
    this.keeperSize = 150,
  });

  final Widget keeper;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Sits under the card, outside the form (New here? Create an account).
  final Widget? footer;

  /// Defaults to popping the route when there is one to pop.
  final VoidCallback? onBack;

  final double keeperSize;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final canPop = onBack != null || Navigator.of(context).canPop();
    final size = keyboard ? keeperSize * 0.66 : keeperSize;
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  if (canPop)
                    GlassIconButton(
                      icon: Icons.arrow_back_rounded,
                      label: 'Back',
                      onTap: onBack ?? () => Navigator.of(context).maybePop(),
                    ),
                ],
              ),
            ),
            TweenAnimationBuilder<double>(
              duration: Motion.medium,
              curve: Motion.settle,
              tween: Tween(end: size),
              builder: (context, s, child) => SizedBox(
                height: s,
                child: Center(child: SizedBox.square(dimension: s, child: child)),
              ),
              child: Hero(tag: 'keeper', child: keeper),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _Card(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    Tokens.gutter,
                    28,
                    Tokens.gutter,
                    28 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineSmall),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 24),
                    ...children,
                    if (footer != null) ...[
                      const SizedBox(height: 20),
                      Center(child: footer!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const radius = BorderRadius.vertical(top: Radius.circular(Tokens.cardRadius));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 40, offset: const Offset(0, -6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.card.withValues(alpha: 0.82),
              borderRadius: radius,
              border: Border(top: BorderSide(color: p.eye.withValues(alpha: 0.5))),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A round, frosted icon button (back, close).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.card.withValues(alpha: 0.6),
                border: Border.all(color: p.line),
              ),
              child: Icon(icon, size: 21, color: p.ink),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tappable word or two in the accent colour (Forgot password?, Sign in).
class LinkText extends StatelessWidget {
  const LinkText(this.text, {super.key, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: p.accentDeep,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: Theme.of(context)
            .textTheme
            .labelMedium!
            .copyWith(fontWeight: FontWeight.w700),
      ),
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

/// "New here? Create an account": a prompt and a link that can wrap.
class SwitchPrompt extends StatelessWidget {
  const SwitchPrompt({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: Theme.of(context).textTheme.bodyMedium),
        LinkText(action, onTap: onTap),
      ],
    );
  }
}
