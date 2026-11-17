import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/auth_repository.dart';
import 'state/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final results = await Future.wait([
    SharedPreferences.getInstance(),
    DemoAccount.load(),
  ]);
  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(results[0] as SharedPreferences),
        demoAccountProvider.overrideWithValue(results[1] as DemoAccount),
      ],
      child: const LatchApp(),
    ),
  );
}
