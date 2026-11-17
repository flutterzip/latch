import 'dart:convert';

import 'package:flutter/services.dart';

import '../config/timing.dart';
import '../widgets/social_buttons.dart';

/// The signed-in person.
class Account {
  const Account({required this.name, required this.email, this.avatar});

  final String name;
  final String email;

  /// `asset:people/x.png`, or null for the initial.
  final String? avatar;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  Account copyWith({String? name, String? email}) =>
      Account(name: name ?? this.name, email: email ?? this.email, avatar: avatar);

  Map<String, Object?> toJson() => {'name': name, 'email': email, 'avatar': avatar};

  factory Account.fromJson(Map<String, Object?> j) => Account(
        name: j['name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        avatar: j['avatar'] as String?,
      );
}

/// Everything that can go wrong, named so each screen can say why.
sealed class AuthFailure implements Exception {
  const AuthFailure();
}

class WrongPassword extends AuthFailure {
  const WrongPassword();
}

class WrongCode extends AuthFailure {
  const WrongCode();
}

class SignInCancelled extends AuthFailure {
  const SignInCancelled();
}

/// The demo person, read from `assets/data/demo.json`.
class DemoAccount {
  const DemoAccount({
    required this.name,
    required this.email,
    required this.password,
    required this.wrongPassword,
    required this.code,
    this.avatar,
  });

  final String name, email, password, wrongPassword, code;
  final String? avatar;

  static Future<DemoAccount> load([AssetBundle? bundle]) async {
    final raw = await (bundle ?? rootBundle).loadString('assets/data/demo.json');
    final j = jsonDecode(raw) as Map<String, Object?>;
    return DemoAccount(
      name: j['name'] as String,
      email: j['email'] as String,
      password: j['password'] as String,
      wrongPassword: j['wrongPassword'] as String,
      code: j['code'] as String,
      avatar: j['avatar'] as String?,
    );
  }

  Account get account => Account(name: name, email: email, avatar: avatar);
}

/// What the screens call. Swap [DemoAuthRepository] for a real one (see
/// [RemoteAuthRepository]) and no widget changes.
abstract interface class AuthRepository {
  Future<Account> signIn(String email, String password);
  Future<Account> signUp({required String name, required String email, required String password});

  /// Real apps plug `sign_in_with_apple` and `google_sign_in` in here and
  /// map a cancel to [SignInCancelled].
  Future<Account> signInWith(SocialProvider provider);

  /// Sends a code by email. Never reveals whether the address has an
  /// account.
  Future<void> sendCode(String email);
  Future<void> verifyCode(String code);
  Future<void> resetPassword(String email, String password);
  Future<void> savePasscode(String passcode);
}

/// Simulates a server with the waits in [AppTiming]. Any well-formed sign-in
/// succeeds as the demo person (keeping the typed email), except the seeded
/// wrong password, so a recording never dead-ends.
class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository(this.demo, {this.latency = true});

  final DemoAccount demo;

  /// Tests pass false to skip every wait.
  final bool latency;

  Future<void> _wait(Duration d) => latency ? AppTiming.wait(d) : Future.value();

  @override
  Future<Account> signIn(String email, String password) async {
    await _wait(AppTiming.signIn);
    if (password == demo.wrongPassword) throw const WrongPassword();
    return demo.account.copyWith(email: email.trim());
  }

  @override
  Future<Account> signUp({required String name, required String email, required String password}) async {
    await _wait(AppTiming.signUp);
    return Account(name: name.trim(), email: email.trim(), avatar: demo.avatar);
  }

  @override
  Future<Account> signInWith(SocialProvider provider) async {
    await _wait(AppTiming.socialSignIn);
    return demo.account;
  }

  @override
  Future<void> sendCode(String email) => _wait(AppTiming.sendCode);

  @override
  Future<void> verifyCode(String code) async {
    await _wait(AppTiming.verifyCode);
    if (code != demo.code) throw const WrongCode();
  }

  @override
  Future<void> resetPassword(String email, String password) => _wait(AppTiming.resetPassword);

  @override
  Future<void> savePasscode(String passcode) => _wait(AppTiming.savePasscode);
}

// A real backend drops in here. Keep every method's failure mapped to an
// [AuthFailure] so the screens keep explaining themselves.
//
// class RemoteAuthRepository implements AuthRepository {
//   RemoteAuthRepository(this.baseUrl);
//   final Uri baseUrl;
//
//   @override
//   Future<Account> signIn(String email, String password) async {
//     final res = await http.post(baseUrl.resolve('/auth/sign-in'),
//         body: {'email': email, 'password': password});
//     if (res.statusCode == 401) throw const WrongPassword();
//     return Account.fromJson(jsonDecode(res.body));
//   }
//   ...
// }
