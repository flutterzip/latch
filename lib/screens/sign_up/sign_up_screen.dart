import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/session.dart';
import '../../widgets/widgets.dart';
import '../passcode/passcode_screen.dart';
import '../sign_in/sign_in_screen.dart';
import '../verify/verify_screen.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final keeper = KeeperController();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  String? nameError, emailError, passwordError;
  bool agreed = false, askedToAgree = false;
  SocialProvider? social;
  bool busy = false, done = false;

  Future<void> createAccount() async {
    setState(() {
      nameError = name.text.trim().isEmpty ? 'Tell us what to call you' : null;
      emailError = Check.emailError(email.text);
      passwordError = Check.password(password.text) < 2 ? 'Use at least 8 characters' : null;
      askedToAgree = !agreed;
    });
    if ([nameError, emailError, passwordError].any((e) => e != null) || !agreed) {
      return keeper.shake();
    }

    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    final account = await ref.read(authRepositoryProvider).signUp(
          name: name.text,
          email: email.text,
          password: password.text,
        );
    setState(() {
      busy = false;
      done = true;
    });
    keeper.cheer();
    await AppTiming.wait(AppTiming.successBeat);
    if (!mounted) return;
    await context.open(VerifyScreen.signUp(account));
    if (mounted) setState(() => done = false);
  }

  Future<void> signUpWith(SocialProvider provider) async {
    if (!agreed) {
      setState(() => askedToAgree = true);
      return keeper.shake();
    }
    setState(() => social = provider);
    final account = await ref.read(authRepositoryProvider).signInWith(provider);
    keeper.cheer();
    if (!mounted) return;
    await context.open(PasscodeScreen(account: account));
    if (mounted) setState(() => social = null);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      keeper: Keeper(controller: keeper),
      keeperSize: 130,
      title: 'Create your account',
      subtitle: 'It takes less than a minute.',
      footer: SwitchPrompt(
        prompt: 'Have an account?',
        action: 'Sign in',
        onTap: () => context.swap(const SignInScreen()),
      ),
      children: [
        Entrance(
          spacing: 18,
          children: [
            SocialButtons(pending: social, enabled: !busy, onPressed: signUpWith),
            const OrDivider(),
            LatchField.name(controller: name, error: nameError, onCaret: keeper.follow),
            LatchField.email(
              controller: email,
              error: emailError,
              onCaret: keeper.follow,
              onFocus: (focused) => focused ? null : keeper.lookAround(),
            ),
            Column(
              children: [
                LatchField.password(
                  controller: password,
                  error: passwordError,
                  onFocus: keeper.cover,
                  onReveal: keeper.peek,
                  onChanged: (v) => setState(() => keeper.mood = 0.2 + Check.password(v) * 0.2),
                ),
                StrengthMeter(password: password.text),
              ],
            ),
            CheckRow(
              value: agreed,
              error: askedToAgree,
              onChanged: (v) => setState(() => agreed = v),
              child: const Text('I agree to the Terms of Service and the Privacy Policy.'),
            ),
            LatchButton(label: 'Create account', busy: busy, done: done, onPressed: createAccount),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    keeper.dispose();
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }
}
