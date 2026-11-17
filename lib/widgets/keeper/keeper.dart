import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../config/motion.dart';
import '../../config/palette.dart';
import 'keeper_controller.dart';
import 'keeper_painter.dart';

export 'keeper_controller.dart';

/// The character in every auth header. It breathes, blinks and looks
/// around on its own, and does what its [controller] says: follows a caret,
/// covers its eyes, peeks, shakes its head, hops.
///
/// Everything moves on one ticker that chases targets with frame-rate
/// independent smoothing, so any reaction can interrupt any other without a
/// jump. The ticker stops when nothing is moving and ambient motion is off.
class Keeper extends StatefulWidget {
  const Keeper({super.key, this.controller, this.size = 150});

  final KeeperController? controller;
  final double size;

  @override
  State<Keeper> createState() => _KeeperState();
}

class _KeeperState extends State<Keeper> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _pose = KeeperPose();
  final _frame = _Repaint();
  final _rng = math.Random();

  KeeperController? _own;
  KeeperController get _c => widget.controller ?? (_own ??= KeeperController());

  Duration _last = Duration.zero;
  double _time = 0;

  // Ambient.
  double _nextBlink = 1.4;
  double _blinkT = -1;
  bool _doubleBlink = false;
  double _nextWander = 1.0;
  Offset _wander = Offset.zero;

  // Events: seconds since each started, or -1 when idle.
  int _seenSeq = 0;
  double _shakeT = -1, _cheerT = -1, _bumpT = -1, _waveT = -1;
  double _swayVel = 0;

  bool _loops = true;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _seenSeq = _c.eventSeq;
    _pose
      ..mood = _c.mood
      ..cover = _c.covering ? 1 : 0
      ..peek = _c.peeking ? 1 : 0;
    _c.addListener(_onController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loops = Motion.loops(context);
    _reduced = Motion.reduced(context);
    _wake();
  }

  @override
  void didUpdateWidget(Keeper old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _own)?.removeListener(_onController);
      _c.addListener(_onController);
      _seenSeq = _c.eventSeq;
      _wake();
    }
  }

  void _onController() {
    if (_c.eventSeq != _seenSeq) {
      _seenSeq = _c.eventSeq;
      switch (_c.event) {
        case KeeperEvent.shake:
          _shakeT = 0;
        case KeeperEvent.cheer:
          _cheerT = 0;
        case KeeperEvent.bump:
          _bumpT = 0;
        case KeeperEvent.wave:
          _waveT = 0;
        case null:
          break;
      }
    }
    _wake();
  }

  void _wake() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _time += dt;
    final moving = _step(dt);
    _frame.ping();
    if (!moving && !_loops) _ticker.stop();
  }

  /// Advances every part by [dt] seconds. Returns whether anything is still
  /// on its way somewhere.
  bool _step(double dt) {
    final c = _c;
    final p = _pose;
    var moving = false;

    double chase(double from, double to, double rate) {
      if (_reduced) return to;
      final next = from + (to - from) * (1 - math.exp(-rate * dt));
      if ((next - to).abs() > 0.002) moving = true;
      return (next - to).abs() < 0.0005 ? to : next;
    }

    // Gaze: the controller's target, or a slow wander when idle.
    var gaze = c.gaze;
    if (gaze == null && _loops) {
      _nextWander -= dt;
      if (_nextWander <= 0) {
        _nextWander = 1.6 + _rng.nextDouble() * 2.6;
        _wander = _rng.nextDouble() < 0.35
            ? Offset.zero
            : Offset(_rng.nextDouble() * 1.2 - 0.6, _rng.nextDouble() * 0.7 - 0.4);
      }
      gaze = _wander;
    }
    gaze ??= Offset.zero;
    final oldX = p.gazeX;
    p.gazeX = chase(p.gazeX, gaze.dx, Motion.gazeFollow);
    p.gazeY = chase(p.gazeY, gaze.dy, Motion.gazeFollow);

    p.cover = chase(p.cover, c.covering ? 1 : 0, Motion.pawFollow);
    p.peek = chase(p.peek, c.covering && c.peeking ? 1 : 0, Motion.pawFollow);
    p.mood = chase(p.mood, c.mood, Motion.moodFollow);

    // The antenna is a damped spring hanging off the head.
    if (!_reduced) {
      final pull = -(p.gazeX - oldX) / math.max(dt, 1e-3) * 1.4;
      _swayVel += (pull - p.sway * 90 - _swayVel * 11) * dt;
      p.sway += _swayVel * dt;
      if (p.sway.abs() > 0.05 || _swayVel.abs() > 0.05) moving = true;
    }

    // Blinking and breathing only while ambient motion is on.
    if (_loops) {
      p.breathe = math.sin(_time * 1.9);
      _nextBlink -= dt;
      if (_nextBlink <= 0 && _blinkT < 0) {
        _blinkT = 0;
        _doubleBlink = _rng.nextDouble() < 0.22;
        _nextBlink = 2.4 + _rng.nextDouble() * 3.2;
      }
    } else {
      p.breathe = 0;
    }
    if (_blinkT >= 0) {
      _blinkT += dt;
      final len = Motion.blink.inMicroseconds / 1e6;
      final total = _doubleBlink ? len * 2.3 : len;
      final local = _blinkT % (len * 1.3);
      p.lid = local < len ? math.sin(local / len * math.pi) : 0;
      if (_blinkT >= total) {
        _blinkT = -1;
        p.lid = 0;
      }
      moving = true;
    }

    // Head shake: three swings that die away.
    if (_shakeT >= 0) {
      _shakeT += dt;
      final len = Motion.headShake.inMicroseconds / 1e6;
      final t = (_shakeT / len).clamp(0.0, 1.0);
      p.shake = math.sin(t * math.pi * 6) * 11 * (1 - t);
      if (t >= 1) {
        _shakeT = -1;
        p.shake = 0;
      }
      moving = true;
    }

    // Cheer: happy eyes, a hop with a squash on landing, then back.
    if (_cheerT >= 0) {
      _cheerT += dt;
      final len = Motion.hop.inMicroseconds / 1e6;
      final t = _cheerT / len;
      p.happy = t < 2.2 ? 1 : (1 - (t - 2.2) * 3).clamp(0.0, 1.0);
      if (t < 1) {
        p.hop = math.sin(t * math.pi) * 26;
        p.squash = 0;
      } else if (t < 1.35) {
        p.hop = 0;
        p.squash = math.sin((t - 1) / 0.35 * math.pi) * 0.8;
      } else {
        p.squash = 0;
      }
      if (t >= 2.6) {
        _cheerT = -1;
        p
          ..happy = 0
          ..hop = 0
          ..squash = 0;
      }
      moving = true;
    }

    // Bump: a quick nod.
    if (_bumpT >= 0) {
      _bumpT += dt;
      const len = 0.22;
      final t = (_bumpT / len).clamp(0.0, 1.0);
      p.hop = _cheerT >= 0 ? p.hop : math.sin(t * math.pi) * 5;
      if (t >= 1) {
        _bumpT = -1;
        if (_cheerT < 0) p.hop = 0;
      }
      moving = true;
    }

    // Wave: raise, three swings, lower.
    if (_waveT >= 0) {
      _waveT += dt;
      const len = 1.6;
      final t = (_waveT / len).clamp(0.0, 1.0);
      p.wave = t < 0.15 ? t / 0.15 : (t > 0.85 ? (1 - t) / 0.15 : 1);
      p.swing = math.sin(t * math.pi * 6);
      if (t >= 1) {
        _waveT = -1;
        p
          ..wave = 0
          ..swing = 0;
      }
      moving = true;
    }

    return moving;
  }

  @override
  void dispose() {
    _c.removeListener(_onController);
    _own?.dispose();
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: KeeperPainter(
            pose: _pose,
            body: p.accent,
            bodyLit: p.accentGlow,
            bodyDeep: p.accentDeep,
            eye: p.eye,
            ink: p.face,
            shadow: p.shadow,
            repaint: _frame,
          ),
        ),
      ),
    );
  }
}

class _Repaint extends ChangeNotifier {
  void ping() => notifyListeners();
}
