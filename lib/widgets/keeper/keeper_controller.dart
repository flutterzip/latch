import 'dart:async';

import 'package:flutter/widgets.dart';

/// One-off reactions the keeper plays, then forgets.
enum KeeperEvent { shake, cheer, bump, wave }

/// Tells a [Keeper] where to look and how to feel.
///
/// Screens own one, hand it to the `Keeper` widget and call it from field
/// callbacks:
///
/// ```dart
/// final keeper = KeeperController();
/// LatchField(onCaret: keeper.follow, onFocus: (f) => f ? null : keeper.lookAround());
/// LatchField.password(onFocus: keeper.cover, onReveal: keeper.peek);
/// ```
class KeeperController extends ChangeNotifier {
  Offset? _gaze;
  bool _covering = false;
  bool _peeking = false;
  double _mood = 0.35;
  KeeperEvent? _event;
  int _eventSeq = 0;

  /// Where the eyes point, from (-1, -1) top left to (1, 1) bottom right.
  /// Null lets the keeper look around on its own.
  Offset? get gaze => _gaze;

  /// Paws over the eyes.
  bool get covering => _covering;

  /// One paw lowered just enough to see through.
  bool get peeking => _peeking;

  /// 0 is glum, 0.35 is content, 1 is delighted.
  double get mood => _mood;

  KeeperEvent? get event => _event;
  int get eventSeq => _eventSeq;

  /// Looks at a point. See [gaze].
  void lookAt(Offset gaze) {
    _gaze = Offset(gaze.dx.clamp(-1.0, 1.0), gaze.dy.clamp(-1.0, 1.0));
    notifyListeners();
  }

  /// Watches a caret moving along a field below: [progress] is 0 at the
  /// field's start and 1 at its end.
  void follow(double progress) =>
      lookAt(Offset(-0.85 + progress.clamp(0.0, 1.0) * 1.7, 0.95));

  /// Lets the keeper's eyes wander again.
  void lookAround() {
    _gaze = null;
    notifyListeners();
  }

  /// Covers (or uncovers) the eyes. Hand it straight to a password field's
  /// `onFocus`.
  void cover([bool covering = true]) {
    _covering = covering;
    if (!covering) _peeking = false;
    notifyListeners();
  }

  void uncover() => cover(false);

  /// Peeks through the paws while a password is shown.
  void peek([bool peeking = true]) {
    _peeking = peeking;
    notifyListeners();
  }

  /// How happy the keeper looks, from 0 to 1.
  set mood(double value) {
    final v = value.clamp(0.0, 1.0);
    if (v == _mood) return;
    _mood = v;
    notifyListeners();
  }

  /// Shakes its head: a wrong password, a code that did not match.
  void shake() => _emit(KeeperEvent.shake);

  /// Hops with happy eyes: signed in, verified, all set.
  void cheer() => _emit(KeeperEvent.cheer);

  /// A small nod, for each digit of a code.
  void bump() => _emit(KeeperEvent.bump);

  /// Waves hello.
  void wave() => _emit(KeeperEvent.wave);

  final _timers = <Timer>[];
  bool _disposed = false;

  /// Runs [action] after [delay], unless the screen has gone by then.
  ///
  /// ```dart
  /// keeper.later(Motion.entrance, keeper.wave);
  /// ```
  void later(Duration delay, VoidCallback action) {
    _timers.add(Timer(delay, () {
      if (!_disposed) action();
    }));
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _emit(KeeperEvent e) {
    _event = e;
    _eventSeq++;
    notifyListeners();
  }
}
