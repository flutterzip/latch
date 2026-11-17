import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/brand.dart';
import '../../data/auth_repository.dart';
import '../../state/session.dart';
import '../../widgets/widgets.dart';
import '../welcome/welcome_screen.dart';

/// Where a signed-in person lands: a greeting, their account and security
/// at a glance, and the way back out.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final keeper = KeeperController()..mood = 0.8;

  @override
  void initState() {
    super.initState();
    keeper.later(Motion.route, keeper.wave);
  }

  Future<void> signOut() async {
    keeper.wave();
    await ref.read(sessionProvider.notifier).signOut();
    if (mounted) context.restart(const WelcomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(sessionProvider);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Tokens.gutter, 8, Tokens.gutter, 32),
          children: [
            Row(
              children: [
                Expanded(child: Text(AppBrand.name, style: text.titleMedium)),
                Avatar(account: account, size: 42),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 12, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Tokens.cardRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [p.accentWash, p.card],
                ),
                border: Border.all(color: p.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Entrance(
                      delay: Motion.medium,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome, ${account?.firstName ?? ''}'.trim(), style: text.headlineSmall),
                        const SizedBox(height: 6),
                        Text('You are signed in and everything is in order.', style: text.bodyMedium),
                      ],
                    ),
                  ),
                  SizedBox.square(
                    dimension: 112,
                    child: GestureDetector(
                      onTap: keeper.cheer,
                      child: Hero(tag: 'keeper', child: Keeper(controller: keeper)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Entrance(
              delay: Motion.medium,
              spacing: 10,
              children: [
                Text('Your account', style: text.titleMedium),
                const SizedBox(height: 4),
                _Row(icon: Icons.alternate_email_rounded, title: 'Email', value: account?.email ?? ''),
                const _Row(icon: Icons.verified_rounded, title: 'Email verified', value: 'Yes'),
                const _Row(icon: Icons.lock_rounded, title: 'Passcode', value: 'On'),
                const _Row(icon: Icons.face_retouching_natural_rounded, title: 'Face ID', value: 'Ready'),
                _Row(icon: Icons.schedule_rounded, title: 'Signed in', value: _signedInAt()),
                const SizedBox(height: 22),
                LatchButton.ghost(label: 'Sign out', icon: Icons.logout_rounded, onPressed: signOut),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _signedInAt() {
    final t = TimeOfDay.now();
    return 'Today at ${t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod}:${t.minute.toString().padLeft(2, '0')} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  @override
  void dispose() {
    keeper.dispose();
    super.dispose();
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title, value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: p.card.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(Tokens.fieldRadius),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: p.accentWash, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 19, color: p.accentDeep),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: text.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(value, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

/// The person's photo, or their initial when there is none or it fails to
/// load.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.account, this.size = 40});

  final Account? account;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final initial = Container(
      color: p.accent,
      alignment: Alignment.center,
      child: Text(
        (account?.name.isNotEmpty ?? false) ? account!.name[0].toUpperCase() : '?',
        style: Theme.of(context).textTheme.titleMedium!.copyWith(color: p.onAccent),
      ),
    );
    final ref = account?.avatar;
    return Semantics(
      label: 'Profile photo',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.accent, width: 2)),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: ref != null && ref.startsWith('asset:')
              ? Image.asset(
                  'assets/images/${ref.substring(6)}',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => initial,
                )
              : initial,
        ),
      ),
    );
  }
}
