import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/auth_repository.dart';

/// Overridden in `main.dart` once the seed and preferences have loaded.
final demoAccountProvider = Provider<DemoAccount>((_) => throw UnimplementedError());
final prefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => DemoAuthRepository(ref.watch(demoAccountProvider)),
);

/// Who is signed in, persisted so a relaunch resumes in the right place.
final sessionProvider = NotifierProvider<SessionNotifier, Account?>(SessionNotifier.new);

class SessionNotifier extends Notifier<Account?> {
  static const _key = 'latch.session.v1';

  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  Account? build() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return Account.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      return null;
    }
  }

  Future<void> signedIn(Account account) async {
    state = account;
    await _prefs.setString(_key, jsonEncode(account.toJson()));
  }

  Future<void> signOut() async {
    state = null;
    await _prefs.remove(_key);
  }
}

/// Demo settings: theme and whether the demo hints show.
class DemoSettings {
  const DemoSettings({this.theme = ThemeMode.system, this.hints = true});

  final ThemeMode theme;
  final bool hints;

  DemoSettings copyWith({ThemeMode? theme, bool? hints}) =>
      DemoSettings(theme: theme ?? this.theme, hints: hints ?? this.hints);
}

final demoSettingsProvider =
    NotifierProvider<DemoSettingsNotifier, DemoSettings>(DemoSettingsNotifier.new);

class DemoSettingsNotifier extends Notifier<DemoSettings> {
  static const _theme = 'latch.theme.v1';
  static const _hints = 'latch.hints.v1';

  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  DemoSettings build() => DemoSettings(
        theme: ThemeMode.values.asNameMap()[_prefs.getString(_theme)] ?? ThemeMode.system,
        hints: _prefs.getBool(_hints) ?? true,
      );

  Future<void> setTheme(ThemeMode mode) async {
    state = state.copyWith(theme: mode);
    await _prefs.setString(_theme, mode.name);
  }

  Future<void> setHints(bool on) async {
    state = state.copyWith(hints: on);
    await _prefs.setBool(_hints, on);
  }
}

/// Puts the demo back to its first launch: signed out, default settings.
Future<void> resetDemo(WidgetRef ref) async {
  await ref.read(prefsProvider).clear();
  ref.invalidate(sessionProvider);
  ref.invalidate(demoSettingsProvider);
}
