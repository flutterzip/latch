import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../state/session.dart';
import '../../widgets/widgets.dart';
import '../new_password/new_password_screen.dart';
import '../passcode/passcode_screen.dart';

/// Six digits sent by email, after signing up or to reset a password.
class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen.signUp(Account this.account, {super.key}) : email = null;
  const VerifyScreen.reset(String this.email, {super.key}) : account = null;

  final Account? account;
  final String? email;

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  final keeper = KeeperController();
  final code = TextEditingController();
  bool wrong = false, right = false;

  String get email => widget.email ?? widget.account!.email;

  void typed(String value) {
    keeper.follow(value.length / 6);
    keeper.bump();
    if (wrong) setState(() => wrong = false);
  }

  Future<void> verify(String value) async {
    try {
      await ref.read(authRepositoryProvider).verifyCode(value);
      setState(() => right = true);
      keeper.cheer();
      await AppTiming.wait(AppTiming.successBeat);
      if (!mounted) return;
      final account = widget.account;
      if (account != null) {
        context.swap(PasscodeScreen(account: account));
      } else {
        context.swap(NewPasswordScreen(email: email));
      }
    } on WrongCode {
      setState(() => wrong = true);
      keeper.shake();
      keeper.later(Motion.shake, code.clear);
    }
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(demoAccountProvider);
    return AuthScaffold(
      keeper: Keeper(controller: keeper),
      title: 'Check your email',
      subtitle: 'We sent a 6-digit code to $email.',
      children: [
        Entrance(
          spacing: 22,
          children: [
            CodeInput(
              controller: code,
              error: wrong,
              success: right,
              onChanged: typed,
              onCompleted: verify,
            ),
            AnimatedSwitcher(
              duration: Motion.short,
              child: wrong
                  ? Text(
                      'That code did not match. Check the latest email and try again.',
                      key: const ValueKey('wrong'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(color: context.palette.error),
                    )
                  : Center(
                      child: ResendTimer(
                        onResend: () => ref.read(authRepositoryProvider).sendCode(email),
                      ),
                    ),
            ),
          ],
        ),
        DemoHint(
          text: 'Your code is ${demo.code}',
          onUse: () {
            code.text = demo.code;
            typed(demo.code);
            verify(demo.code);
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    keeper.dispose();
    code.dispose();
    super.dispose();
  }
}
