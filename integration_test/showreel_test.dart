// Drives the real app on the simulator at human speed, for recording and
// for judging motion frame by frame:
//   tool/rec.sh signIn
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:latch/app.dart';
import 'package:latch/data/auth_repository.dart';
import 'package:latch/state/session.dart';
import 'package:latch/widgets/code_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

const reel = String.fromEnvironment('reel', defaultValue: 'signIn');

Future<void> pause(WidgetTester t, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

/// Types one character at a time, like a person.
Future<void> typeInto(WidgetTester t, Finder field, String text, {int ms = 110}) async {
  await t.tap(field);
  await pause(t, 350);
  var current = '';
  for (final ch in text.split('')) {
    current += ch;
    await t.enterText(field, current);
    await pause(t, ms + (ch == '@' || ch == '.' ? 140 : 0));
  }
}

Finder field(int i) => find.byType(TextField).at(i);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('showreel $reel', (t) async {
    SharedPreferences.setMockInitialValues({'latch.hints.v1': false});
    final prefs = await SharedPreferences.getInstance();
    final demo = await DemoAccount.load();
    await t.pumpWidget(ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        demoAccountProvider.overrideWithValue(demo),
      ],
      child: const LatchApp(),
    ));
    await pause(t, 3600); // splash, then Welcome waves

    switch (reel) {
      case 'signIn':
        await t.tap(find.text('I already have an account'));
        await pause(t, 1600);
        await typeInto(t, field(0), 'hello@flutterzip.com');
        await pause(t, 500);
        await typeInto(t, field(1), 'wrongpass', ms: 140);
        await pause(t, 700);
        await t.tap(find.bySemanticsLabel('Show password'));
        await pause(t, 1400);
        await t.tap(find.bySemanticsLabel('Hide password'));
        await pause(t, 600);
        await t.tap(find.text('Sign in').last);
        await pause(t, 2800);
        await typeInto(t, field(1), 'latch1234', ms: 130);
        await pause(t, 400);
        await t.tap(find.text('Sign in').last);
        await pause(t, 4500);
      case 'signUp':
        await t.tap(find.text('Create account'));
        await pause(t, 1600);
        await typeInto(t, field(0), 'Olympicson');
        await typeInto(t, field(1), 'hello@flutterzip.com');
        await typeInto(t, field(2), 'a lamp in the window', ms: 120);
        await pause(t, 600);
        FocusManager.instance.primaryFocus?.unfocus();
        await pause(t, 600);
        await t.tap(find.text('I agree to the Terms of Service and the Privacy Policy.'));
        await pause(t, 700);
        await t.tap(find.text('Create account').last);
        await pause(t, 4200);
        final code = find.descendant(of: find.byType(CodeInput), matching: find.byType(TextField));
        Future<void> typeCode(String digits) async {
          for (var i = 1; i <= digits.length; i++) {
            await t.enterText(code, digits.substring(0, i));
            await pause(t, 260);
          }
        }
        await typeCode('123456');
        await pause(t, 2400);
        await typeCode('246810');
        await pause(t, 3000);
        for (final d in '25802580'.split('')) {
          await t.tap(find.bySemanticsLabel(d).first);
          await pause(t, 280);
        }
        await pause(t, 5000);
    }
  });
}
