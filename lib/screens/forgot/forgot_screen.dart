import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/session.dart';
import '../../widgets/widgets.dart';
import '../verify/verify_screen.dart';

class ForgotScreen extends ConsumerStatefulWidget {
  const ForgotScreen({super.key});

  @override
  ConsumerState<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends ConsumerState<ForgotScreen> {
  final keeper = KeeperController();
  final email = TextEditingController();
  String? emailError;
  bool busy = false, done = false;

  Future<void> sendCode() async {
    setState(() => emailError = Check.emailError(email.text));
    if (emailError != null) return keeper.shake();

    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    // The same answer whether or not the address has an account.
    await ref.read(authRepositoryProvider).sendCode(email.text);
    setState(() {
      busy = false;
      done = true;
    });
    keeper.cheer();
    await AppTiming.wait(AppTiming.successBeat);
    if (mounted) context.swap(VerifyScreen.reset(email.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(demoAccountProvider);
    return AuthScaffold(
      keeper: Keeper(controller: keeper),
      title: 'Forgot your password?',
      subtitle: 'Enter your email and we will send you a code to reset it.',
      children: [
        Entrance(
          spacing: 22,
          children: [
            LatchField.email(
              controller: email,
              error: emailError,
              textInputAction: TextInputAction.send,
              onCaret: keeper.follow,
              onFocus: (focused) => focused ? null : keeper.lookAround(),
              onSubmitted: (_) => sendCode(),
            ),
            LatchButton(label: 'Send code', busy: busy, done: done, onPressed: sendCode),
          ],
        ),
        DemoHint(text: demo.email, onUse: () => email.text = demo.email),
      ],
    );
  }

  @override
  void dispose() {
    keeper.dispose();
    email.dispose();
    super.dispose();
  }
}
