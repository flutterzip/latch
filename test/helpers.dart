import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latch/config/motion.dart';
import 'package:latch/config/theme.dart';
import 'package:latch/config/timing.dart';
import 'package:latch/data/auth_repository.dart';
import 'package:latch/state/session.dart';
import 'package:latch/widgets/backdrop.dart';
import 'package:shared_preferences/shared_preferences.dart';

const demo = DemoAccount(
  name: 'Olympicson',
  email: 'hello@flutterzip.com',
  password: 'latch1234',
  wrongPassword: 'wrongpass',
  code: '246810',
  avatar: 'asset:people/olympicson.png',
);

/// Every test runs without waits, without ambient loops, on a phone-sized
/// screen.
Future<ProviderContainer> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  Map<String, Object> prefs = const {},
  ThemeMode theme = ThemeMode.light,
}) async {
  Motion.ambient = false;
  AppTiming.scale = 0;
  tester.view.physicalSize = const Size(1290, 2796);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(sp),
    demoAccountProvider.overrideWithValue(demo),
    authRepositoryProvider.overrideWithValue(DemoAuthRepository(demo, latency: false)),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: theme,
        builder: (context, child) => AuthBackdrop(child: child!),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Enters text in the [LatchField] whose title is [label].
Future<void> fill(WidgetTester tester, String label, String text) async {
  final field = find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
    matching: find.byType(TextField),
  );
  await tester.enterText(field.first, text);
  await tester.pump();
}
