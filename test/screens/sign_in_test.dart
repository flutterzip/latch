import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latch/screens/home/home_screen.dart';
import 'package:latch/screens/sign_in/sign_in_screen.dart';
import 'package:latch/state/session.dart';
import 'package:latch/widgets/widgets.dart';

import '../helpers.dart';

void main() {
  testWidgets('shows the social buttons, both fields and the button', (tester) async {
    await pumpScreen(tester, const SignInScreen());
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(SocialButtons), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.widgetWithText(LatchButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('an empty form names every missing field', (tester) async {
    await pumpScreen(tester, const SignInScreen());
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('the seeded wrong password is refused', (tester) async {
    await pumpScreen(tester, const SignInScreen());
    await fill(tester, 'Email', demo.email);
    await fill(tester, 'Password', demo.wrongPassword);
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('That password is not right'), findsOneWidget);
  });

  testWidgets('editing a field hides its old error', (tester) async {
    await pumpScreen(tester, const SignInScreen());
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    await fill(tester, 'Email', 'a');
    await tester.pumpAndSettle();
    expect(find.text('Enter your email'), findsNothing);
  });

  testWidgets('any other password signs in and lands on Home', (tester) async {
    final container = await pumpScreen(tester, const SignInScreen());
    await fill(tester, 'Email', 'me@example.com');
    await fill(tester, 'Password', 'anything at all');
    await tester.tap(find.text('Sign in').last);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Welcome, Olympicson'), findsOneWidget);
    expect(container.read(sessionProvider)!.email, 'me@example.com');
  });

  testWidgets('the demo hint fills in the demo account', (tester) async {
    await pumpScreen(tester, const SignInScreen());
    await tester.tap(find.text('Use'));
    await tester.pump();
    expect(find.text(demo.email), findsWidgets);
  });

  testWidgets('focusing the password covers the keeper\'s eyes', (tester) async {
    await pumpScreen(tester, const SignInScreen());
    final keeper = tester.widget<Keeper>(find.byType(Keeper)).controller!;
    await tester.tap(find.byType(TextField).at(1));
    await tester.pump();
    expect(keeper.covering, isTrue);
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    expect(keeper.covering, isFalse);
  });

  testWidgets('typing in the email moves the keeper\'s gaze along', (tester) async {
    await pumpScreen(tester, const SignInScreen());
    final keeper = tester.widget<Keeper>(find.byType(Keeper)).controller!;
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    final start = keeper.gaze!.dx;
    await tester.enterText(find.byType(TextField).first, 'a.long.address@example.com');
    await tester.pump();
    expect(keeper.gaze!.dx, greaterThan(start));
  });

  testWidgets('demo hints can be hidden', (tester) async {
    await pumpScreen(tester, const SignInScreen(), prefs: {'latch.hints.v1': false});
    expect(find.text('Use'), findsNothing);
  });
}
