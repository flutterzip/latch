import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/brand.dart';
import 'config/theme.dart';
import 'demo/demo_control.dart';
import 'demo/launch_hooks.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/splash.dart';
import 'screens/welcome/welcome_screen.dart';
import 'state/session.dart';
import 'widgets/backdrop.dart';
import 'widgets/routes.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class LatchApp extends ConsumerStatefulWidget {
  const LatchApp({super.key, this.splash = true});

  /// Tests start without the splash.
  final bool splash;

  @override
  ConsumerState<LatchApp> createState() => _LatchAppState();
}

class _LatchAppState extends ConsumerState<LatchApp> {
  late bool _splash = widget.splash;
  final _ready = Completer<void>();
  final _appKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Fonts and the seed are loaded before runApp; give the first screen a
    // frame to build behind the splash before it leaves.
    WidgetsBinding.instance.addPostFrameCallback((_) => _ready.complete());
    if (!_splash) Splash.showing.value = false;
  }

  void _splashGone() {
    setState(() => _splash = false);
    runLaunchHooks(navigatorKey);
  }

  static Route<void> _first(bool signedIn) =>
      LatchRoute<void>(signedIn ? const HomeScreen() : const WelcomeScreen());

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(demoSettingsProvider);
    final signedIn = ref.read(sessionProvider) != null;
    return MaterialApp(
      title: AppBrand.name,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.theme,
      // The first page goes through the same see-through route as every
      // other, so it fades away when the next one covers it.
      onGenerateInitialRoutes: (_) => [_first(signedIn)],
      onGenerateRoute: (_) => _first(signedIn),
      builder: (context, child) => AuthBackdrop(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          // The stack keeps its shape for the app's whole life, so the first
          // screen is never rebuilt when the splash leaves.
          child: Stack(
            children: [
              KeyedSubtree(key: _appKey, child: child!),
              if (_splash) Positioned.fill(child: Splash(ready: _ready.future, onGone: _splashGone)),
              DemoControl(key: const ValueKey('demo'), navigatorKey: navigatorKey),
            ],
          ),
        ),
      ),
    );
  }
}
