import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../state/session.dart';
import '../../widgets/widgets.dart';
import '../all_set/all_set_screen.dart';

/// Choose a 4-digit passcode, then type it again. The keeper covers its
/// eyes the whole time.
class PasscodeScreen extends ConsumerStatefulWidget {
  const PasscodeScreen({super.key, required this.account});

  final Account account;

  @override
  ConsumerState<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends ConsumerState<PasscodeScreen> {
  final keeper = KeeperController()..cover();
  String first = '', typed = '';
  bool confirming = false, wrong = false, right = false;

  void digit(String d) {
    if (typed.length == 4) return;
    setState(() {
      typed += d;
      wrong = false;
    });
    keeper.bump();
    if (typed.length == 4) keeper.later(Motion.quick, next);
  }

  void delete() {
    if (typed.isNotEmpty) setState(() => typed = typed.substring(0, typed.length - 1));
  }

  void startOver() => setState(() {
        first = '';
        typed = '';
        confirming = false;
      });

  Future<void> next() async {
    if (!confirming) {
      return setState(() {
        first = typed;
        typed = '';
        confirming = true;
      });
    }
    if (typed != first) {
      setState(() => wrong = true);
      keeper.shake();
      return keeper.later(Motion.shake, startOver);
    }
    setState(() => right = true);
    await ref.read(authRepositoryProvider).savePasscode(typed);
    keeper
      ..uncover()
      ..cheer();
    await AppTiming.wait(AppTiming.successBeat);
    if (mounted) context.swap(AllSetScreen.signedUp(widget.account));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      keeper: Keeper(controller: keeper),
      keeperSize: 120,
      title: confirming ? 'Type it once more' : 'Choose a passcode',
      subtitle: wrong
          ? 'Those did not match. Choose your passcode again.'
          : 'You will use it to open the app. We will not look.',
      children: [
        Entrance(
          children: [
            Center(
              child: PasscodeDots(filled: typed.length, error: wrong, success: right),
            ),
            const SizedBox(height: 36),
            PasscodePad(onDigit: digit, onDelete: delete, enabled: !right),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    keeper.dispose();
    super.dispose();
  }
}
