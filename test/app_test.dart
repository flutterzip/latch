import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latch/app.dart';
import 'package:latch/config/motion.dart';
import 'package:latch/config/timing.dart';
import 'package:latch/screens/home/home_screen.dart';
import 'package:latch/screens/splash/splash.dart';
import 'package:latch/screens/welcome/welcome_screen.dart';
import 'package:latch/state/session.dart';
import 'package:latch/widgets/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

Future<void> pumpApp(WidgetTester tester, {Map<String, Object> prefs = const {}, bool splash = true}) async {
  Motion.ambient = false;
  AppTiming.scale = 1;
  addTearDown(() => AppTiming.scale = 0);
  tester.view.physicalSize = const Size(1290, 2796);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(sp),
      demoAccountProvider.overrideWithValue(demo),
    ],
    child: LatchApp(splash: splash),
  ));
}

void main() {
  testWidgets('the splash plays, then leaves Welcome without rebuilding it', (tester) async {
    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Splash), findsOneWidget);
    final before = tester.state(find.byType(WelcomeScreen));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(Splash), findsNothing);
    expect(identical(tester.state(find.byType(WelcomeScreen)), before), isTrue);
    expect(Splash.showing.value, isFalse);
  });

  testWidgets('the splash has a text style, so no debug underline', (tester) async {
    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 1600));
    final style = DefaultTextStyle.of(tester.element(find.text('Come on in.').first)).style;
    expect(style.decoration, anyOf(isNull, TextDecoration.none));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('the first page fades out when the next one covers it', (tester) async {
    await pumpApp(tester, splash: false);
    await tester.pumpAndSettle();
    final route = ModalRoute.of(tester.element(find.byType(WelcomeScreen)));
    expect(route, isA<LatchRoute>());
    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();
    final fade = tester.widgetList<FadeTransition>(
      find.ancestor(of: find.byType(WelcomeScreen, skipOffstage: false), matching: find.byType(FadeTransition)),
    );
    expect(fade.any((f) => f.opacity.value == 0), isTrue);
  });

  testWidgets('a stored session opens Home', (tester) async {
    await pumpApp(
      tester,
      splash: false,
      prefs: {'latch.session.v1': '{"name":"Olympicson","email":"hello@flutterzip.com"}'},
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Demo settings switches to dark and hides the hints', (tester) async {
    await pumpApp(tester, splash: false);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Demo settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(WelcomeScreen))).brightness, Brightness.dark);
    await tester.tap(find.text('Demo hints'));
    await tester.pumpAndSettle();
    expect(find.text('Sample credentials and codes are hidden'), findsOneWidget);
  });
}
