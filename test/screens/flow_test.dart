import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latch/data/auth_repository.dart';
import 'package:latch/screens/all_set/all_set_screen.dart';
import 'package:latch/screens/forgot/forgot_screen.dart';
import 'package:latch/screens/home/home_screen.dart';
import 'package:latch/screens/new_password/new_password_screen.dart';
import 'package:latch/screens/passcode/passcode_screen.dart';
import 'package:latch/screens/sign_in/sign_in_screen.dart';
import 'package:latch/screens/sign_up/sign_up_screen.dart';
import 'package:latch/screens/verify/verify_screen.dart';
import 'package:latch/screens/welcome/welcome_screen.dart';
import 'package:latch/state/session.dart';
import 'package:latch/widgets/widgets.dart';

import '../helpers.dart';

const ada = Account(name: 'Ada Lovelace', email: 'ada@example.com');

Future<void> typeCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField), code);
  await tester.pumpAndSettle();
}

Future<void> tapKeys(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.bySemanticsLabel(d).first);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  group('Welcome', () {
    testWidgets('offers both ways in', (tester) async {
      await pumpScreen(tester, const WelcomeScreen());
      expect(find.text('Come on in.'), findsOneWidget);
      await tester.tap(find.text('I already have an account'));
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('Create account opens sign up', (tester) async {
      await pumpScreen(tester, const WelcomeScreen());
      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpScreen), findsOneWidget);
    });
  });

  group('Sign up', () {
    testWidgets('asks for every field and the terms', (tester) async {
      await pumpScreen(tester, const SignUpScreen());
      await tester.ensureVisible(find.text('Create account').last);
      await tester.pump();
      await tester.tap(find.text('Create account').last);
      await tester.pumpAndSettle();
      expect(find.text('Tell us what to call you'), findsOneWidget);
      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Use at least 8 characters'), findsOneWidget);
      expect(find.byType(VerifyScreen), findsNothing);
    });

    testWidgets('a social sign up still needs the terms', (tester) async {
      await pumpScreen(tester, const SignUpScreen());
      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();
      expect(find.byType(PasscodeScreen), findsNothing);
      final row = tester.widget<CheckRow>(find.byType(CheckRow));
      expect(row.error, isTrue);
    });

    testWidgets('a complete form goes on to the code', (tester) async {
      await pumpScreen(tester, const SignUpScreen());
      await fill(tester, 'Full name', 'Ada Lovelace');
      await fill(tester, 'Email', 'ada@example.com');
      await fill(tester, 'Password', 'a long enough password');
      expect(find.text('Strong'), findsOneWidget);
      await tester.ensureVisible(find.byType(CheckRow));
      await tester.pump();
      await tester.tap(find.byType(CheckRow));
      await tester.ensureVisible(find.text('Create account').last);
      await tester.pump();
      await tester.tap(find.text('Create account').last);
      await tester.pumpAndSettle();
      expect(find.byType(VerifyScreen), findsOneWidget);
      expect(find.textContaining('code to ada@example.com'), findsOneWidget);
    });
  });

  group('Verify', () {
    testWidgets('a wrong code is refused and cleared', (tester) async {
      await pumpScreen(tester, const VerifyScreen.signUp(ada));
      await typeCode(tester, '111111');
      expect(find.textContaining('did not match'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
      expect(find.byType(PasscodeScreen), findsNothing);
    });

    testWidgets('the right code after sign up asks for a passcode', (tester) async {
      await pumpScreen(tester, const VerifyScreen.signUp(ada));
      await typeCode(tester, demo.code);
      expect(find.byType(PasscodeScreen), findsOneWidget);
    });

    testWidgets('the right code after a reset asks for a new password', (tester) async {
      await pumpScreen(tester, const VerifyScreen.reset('ada@example.com'));
      await typeCode(tester, demo.code);
      expect(find.byType(NewPasswordScreen), findsOneWidget);
    });

    testWidgets('the demo hint enters the code', (tester) async {
      await pumpScreen(tester, const VerifyScreen.signUp(ada));
      await tester.tap(find.text('Use'));
      await tester.pumpAndSettle();
      expect(find.byType(PasscodeScreen), findsOneWidget);
    });
  });

  group('Passcode', () {
    testWidgets('the keeper covers its eyes the whole time', (tester) async {
      await pumpScreen(tester, const PasscodeScreen(account: ada));
      final keeper = tester.widget<Keeper>(find.byType(Keeper)).controller!;
      expect(keeper.covering, isTrue);
    });

    testWidgets('two different passcodes start over', (tester) async {
      await pumpScreen(tester, const PasscodeScreen(account: ada));
      await tapKeys(tester, '1234');
      expect(find.text('Type it once more'), findsOneWidget);
      await tapKeys(tester, '4321');
      expect(find.text('Choose a passcode'), findsOneWidget);
      expect(find.textContaining('did not match'), findsOneWidget);
    });

    testWidgets('delete removes the last digit', (tester) async {
      await pumpScreen(tester, const PasscodeScreen(account: ada));
      await tapKeys(tester, '12');
      await tester.tap(find.bySemanticsLabel('Delete'));
      await tester.pump();
      expect(find.bySemanticsLabel('1 of 4 digits entered'), findsOneWidget);
    });

    testWidgets('matching passcodes finish the sign up', (tester) async {
      await pumpScreen(tester, const PasscodeScreen(account: ada));
      await tapKeys(tester, '2580');
      await tapKeys(tester, '2580');
      expect(find.byType(AllSetScreen), findsOneWidget);
      expect(find.text('You are all set, Ada'), findsOneWidget);
    });
  });

  group('Forgot password', () {
    testWidgets('needs a real email', (tester) async {
      await pumpScreen(tester, const ForgotScreen());
      await fill(tester, 'Email', 'not an email');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      expect(find.text('Enter an email like name@example.com'), findsOneWidget);
    });

    testWidgets('sends a code to any address', (tester) async {
      await pumpScreen(tester, const ForgotScreen());
      await fill(tester, 'Email', 'nobody@example.com');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      expect(find.byType(VerifyScreen), findsOneWidget);
    });
  });

  group('New password', () {
    testWidgets('the two passwords must match', (tester) async {
      await pumpScreen(tester, const NewPasswordScreen(email: 'ada@example.com'));
      await fill(tester, 'New password', 'correct horse battery');
      await fill(tester, 'Confirm password', 'correct horse');
      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();
      expect(find.text('The two passwords do not match'), findsOneWidget);
    });

    testWidgets('a matching pair finishes the reset', (tester) async {
      await pumpScreen(tester, const NewPasswordScreen(email: 'ada@example.com'));
      await fill(tester, 'New password', 'correct horse battery');
      await fill(tester, 'Confirm password', 'correct horse battery');
      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();
      expect(find.text('Password updated'), findsOneWidget);
      await tester.tap(find.text('Back to sign in'));
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);
    });
  });

  group('All set and Home', () {
    testWidgets('Continue signs the new account in', (tester) async {
      final container = await pumpScreen(tester, const AllSetScreen.signedUp(ada));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Welcome, Ada'), findsOneWidget);
      expect(container.read(sessionProvider)!.name, 'Ada Lovelace');
    });

    testWidgets('Sign out goes back to Welcome and forgets the session', (tester) async {
      final container = await pumpScreen(
        tester,
        const HomeScreen(),
        prefs: {'latch.session.v1': '{"name":"Olympicson","email":"hello@flutterzip.com"}'},
      );
      expect(find.text('Welcome, Olympicson'), findsOneWidget);
      await tester.ensureVisible(find.text('Sign out'));
      await tester.pump();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(container.read(sessionProvider), isNull);
    });

    testWidgets('a missing photo falls back to the initial', (tester) async {
      await pumpScreen(
        tester,
        const Scaffold(body: Avatar(account: Account(name: 'Ada', email: 'a@b.co', avatar: 'asset:people/missing.png'))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
