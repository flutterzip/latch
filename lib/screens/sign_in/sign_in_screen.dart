import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../state/session.dart';
import '../../widgets/widgets.dart';
import '../forgot/forgot_screen.dart';
import '../home/home_screen.dart';
import '../sign_up/sign_up_screen.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final keeper = KeeperController();
  final email = TextEditingController();
  final password = TextEditingController();
  String? emailError, passwordError;
  SocialProvider? social;
  bool busy = false, done = false;

  Future<void> signIn() async {
    setState(() {
      emailError = Check.emailError(email.text);
      passwordError = password.text.isEmpty ? 'Enter your password' : null;
    });
    if (emailError != null || passwordError != null) return keeper.shake();

    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    try {
      final account = await ref.read(authRepositoryProvider).signIn(email.text, password.text);
      await welcome(account);
    } on WrongPassword {
      setState(() {
        busy = false;
        passwordError = 'That password is not right. Try again or reset it.';
      });
      keeper.shake();
    }
  }

  Future<void> signInWith(SocialProvider provider) async {
    setState(() => social = provider);
    final account = await ref.read(authRepositoryProvider).signInWith(provider);
    await welcome(account);
  }

  Future<void> welcome(Account account) async {
    setState(() {
      busy = false;
      done = true;
    });
    keeper.cheer();
    await AppTiming.wait(AppTiming.successBeat);
    await ref.read(sessionProvider.notifier).signedIn(account);
    if (mounted) context.restart(const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(demoAccountProvider);
    return AuthScaffold(
      keeper: Keeper(controller: keeper),
      title: 'Welcome back',
      subtitle: 'Sign in to pick up where you left off.',
      footer: SwitchPrompt(
        prompt: 'New here?',
        action: 'Create an account',
        onTap: () => context.swap(const SignUpScreen()),
      ),
      children: [
        Entrance(
          spacing: 18,
          children: [
            SocialButtons(pending: social, enabled: !busy, onPressed: signInWith),
            const OrDivider(),
            LatchField.email(
              controller: email,
              error: emailError,
              onCaret: keeper.follow,
              onFocus: (focused) => focused ? null : keeper.lookAround(),
              onChanged: (v) => keeper.mood = Check.email(v) ? 0.7 : 0.35,
            ),
            LatchField.password(
              controller: password,
              error: passwordError,
              onFocus: keeper.cover,
              onReveal: keeper.peek,
              onSubmitted: (_) => signIn(),
              action: LinkText('Forgot password?', onTap: () => context.open(const ForgotScreen())),
            ),
            LatchButton(label: 'Sign in', busy: busy, done: done, onPressed: signIn),
          ],
        ),
        DemoHint(
          text: '${demo.email} · ${demo.password}',
          onUse: () {
            email.text = demo.email;
            password.text = demo.password;
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    keeper.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }
}
