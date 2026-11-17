import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/session.dart';
import '../../widgets/widgets.dart';
import '../all_set/all_set_screen.dart';

class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final keeper = KeeperController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  String? passwordError, confirmError;
  bool busy = false, done = false;

  Future<void> save() async {
    setState(() {
      passwordError = Check.password(password.text) < 2 ? 'Use at least 8 characters' : null;
      confirmError = confirm.text != password.text ? 'The two passwords do not match' : null;
    });
    if (passwordError != null || confirmError != null) return keeper.shake();

    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    await ref.read(authRepositoryProvider).resetPassword(widget.email, password.text);
    setState(() {
      busy = false;
      done = true;
    });
    keeper.cheer();
    await AppTiming.wait(AppTiming.successBeat);
    if (mounted) context.swap(const AllSetScreen.passwordReset());
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      keeper: Keeper(controller: keeper),
      title: 'Choose a new password',
      subtitle: 'Make it long. A short sentence is easier to remember and harder to guess.',
      children: [
        Entrance(
          spacing: 18,
          children: [
            Column(
              children: [
                LatchField.password(
                  controller: password,
                  label: 'New password',
                  error: passwordError,
                  textInputAction: TextInputAction.next,
                  onFocus: keeper.cover,
                  onReveal: keeper.peek,
                  onChanged: (v) => setState(() => keeper.mood = 0.2 + Check.password(v) * 0.2),
                ),
                StrengthMeter(password: password.text),
              ],
            ),
            LatchField.password(
              controller: confirm,
              label: 'Confirm password',
              hint: 'Type it again',
              error: confirmError,
              onFocus: keeper.cover,
              onReveal: keeper.peek,
              onSubmitted: (_) => save(),
            ),
            LatchButton(label: 'Update password', busy: busy, done: done, onPressed: save),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    keeper.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }
}
