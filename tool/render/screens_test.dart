// ignore_for_file: invalid_use_of_visible_for_testing_member
// Renders every screen, light and dark, to build/screens/<name>_<mode>.png
// with the real fonts. Used for reviewing layouts and for the README.
//   flutter test tool/render/screens_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latch/config/motion.dart';
import 'package:latch/config/theme.dart';
import 'package:latch/config/timing.dart';
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
import 'package:latch/widgets/backdrop.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/helpers.dart' show demo;

const only = String.fromEnvironment('only');

Future<void> loadFonts() async {
  final loader = FontLoader('Bricolage');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Bricolage-$w.ttf').readAsBytesSync())));
  }
  await loader.load();
  final icons = FontLoader('MaterialIcons');
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
  final font = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (font.existsSync()) {
    icons.addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
    await icons.load();
  }
}

void main() {
  const account = Account(name: 'Olympicson', email: 'hello@flutterzip.com', avatar: 'asset:people/olympicson.png');
  final screens = <String, Widget>{
    'welcome': const WelcomeScreen(),
    'sign_in': const SignInScreen(),
    'sign_up': const SignUpScreen(),
    'forgot': const ForgotScreen(),
    'verify': const VerifyScreen.signUp(account),
    'new_password': const NewPasswordScreen(email: 'hello@flutterzip.com'),
    'passcode': const PasscodeScreen(account: account),
    'all_set': const AllSetScreen.signedUp(account),
    'home': const HomeScreen(),
  };

  setUpAll(loadFonts);

  for (final mode in ['light', 'dark']) {
    for (final e in screens.entries) {
      if (only.isNotEmpty && !only.split(',').contains(e.key)) continue;
      testWidgets('${e.key} $mode', (tester) async {
        Motion.ambient = false;
        AppTiming.scale = 0;
        tester.view.physicalSize = const Size(440 * 3, 956 * 3);
        tester.view.devicePixelRatio = 3;
        tester.view.padding = const FakeViewPadding(top: 62 * 3, bottom: 34 * 3);
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({
          'latch.session.v1': '{"name":"Olympicson","email":"hello@flutterzip.com","avatar":"asset:people/olympicson.png"}',
        });
        final sp = await SharedPreferences.getInstance();
        final key = GlobalKey();
        await tester.pumpWidget(ProviderScope(
          overrides: [
            prefsProvider.overrideWithValue(sp),
            demoAccountProvider.overrideWithValue(demo),
          ],
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: mode == 'light' ? ThemeMode.light : ThemeMode.dark,
              builder: (context, child) => AuthBackdrop(child: child!),
              home: e.value,
            ),
          ),
        ));
        await tester.runAsync(() async {
          for (final el in find.byType(Image).evaluate()) {
            final image = (el.widget as Image).image;
            await precacheImage(image, el);
          }
        });
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final img = await boundary.toImage(pixelRatio: 1.5);
          return img.toByteData(format: ui.ImageByteFormat.png);
        });
        File('build/screens/${e.key}_$mode.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes!.buffer.asUint8List());
        await tester.pump(const Duration(seconds: 5));
      });
    }
  }
}
