import 'package:flutter/widgets.dart';

import '../data/auth_repository.dart';
import '../screens/all_set/all_set_screen.dart';
import '../screens/forgot/forgot_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/new_password/new_password_screen.dart';
import '../screens/passcode/passcode_screen.dart';
import '../screens/sign_in/sign_in_screen.dart';
import '../screens/sign_up/sign_up_screen.dart';
import '../screens/verify/verify_screen.dart';
import '../widgets/routes.dart';

/// Opens a screen straight after the splash, for screenshots and
/// recordings: `--dart-define=startRoute=signIn`. Off by default, so a
/// release build is unaffected.
///
/// welcome, signIn, signUp, forgot, verify, newPassword, passcode, allSet,
/// home.
const startRoute = String.fromEnvironment('startRoute');

void runLaunchHooks(GlobalKey<NavigatorState> navigatorKey) {
  final context = navigatorKey.currentContext;
  if (startRoute.isEmpty || context == null) return;
  const demo = Account(name: 'Olympicson', email: 'hello@flutterzip.com', avatar: 'asset:people/olympicson.png');
  final Widget? page = switch (startRoute) {
    'signIn' => const SignInScreen(),
    'signUp' => const SignUpScreen(),
    'forgot' => const ForgotScreen(),
    'verify' => const VerifyScreen.signUp(demo),
    'newPassword' => const NewPasswordScreen(email: 'hello@flutterzip.com'),
    'passcode' => const PasscodeScreen(account: demo),
    'allSet' => const AllSetScreen.signedUp(demo),
    'home' => const HomeScreen(),
    _ => null,
  };
  if (page != null) context.open(page);
}
