import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../state/session.dart';
import '../../widgets/widgets.dart';
import '../home/home_screen.dart';
import '../sign_in/sign_in_screen.dart';

/// The finish line: a new account is ready, or a password was changed.
class AllSetScreen extends ConsumerStatefulWidget {
  const AllSetScreen.signedUp(Account this.account, {super.key});
  const AllSetScreen.passwordReset({super.key}) : account = null;

  final Account? account;

  @override
  ConsumerState<AllSetScreen> createState() => _AllSetScreenState();
}

class _AllSetScreenState extends ConsumerState<AllSetScreen> {
  final keeper = KeeperController()..mood = 1;
  int burst = 0;

  bool get isNew => widget.account != null;

  @override
  void initState() {
    super.initState();
    keeper.later(Motion.medium, keeper.cheer);
  }

  Future<void> next() async {
    final account = widget.account;
    if (account == null) return context.restart(const SignInScreen());
    await ref.read(sessionProvider.notifier).signedIn(account);
    if (mounted) context.restart(const HomeScreen());
  }

  void celebrate() {
    keeper.cheer();
    setState(() => burst++);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
          child: Column(
            children: [
              const Spacer(flex: 3),
              GestureDetector(
                onTap: celebrate,
                child: SparkBurst(
                  play: burst,
                  child: Hero(tag: 'keeper', child: Keeper(controller: keeper, size: 220)),
                ),
              ),
              const Spacer(flex: 2),
              Entrance(
                delay: Motion.short,
                children: [
                  Text(
                    isNew ? 'You are all set, ${widget.account!.firstName}' : 'Password updated',
                    style: text.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isNew
                        ? 'Your email is verified and your passcode is on. Welcome in.'
                        : 'Sign in with your new password. Every other device has been signed out.',
                    style: text.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  LatchButton(label: isNew ? 'Continue' : 'Back to sign in', onPressed: next),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    keeper.dispose();
    super.dispose();
  }
}
