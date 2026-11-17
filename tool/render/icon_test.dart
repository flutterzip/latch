// Draws the app icon (the keeper under its lamp) to assets/brand/icon_1024.png,
// from the same painter the app uses. Then: python3 tool/make_icons.py
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latch/config/palette.dart';
import 'package:latch/widgets/keeper/keeper_painter.dart';

void main() {
  test('icon', () async {
    const s = 1024.0;
    final p = Palette.light;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(const Rect.fromLTWH(0, 0, s, s), Paint()..color = p.paper);
    c.drawCircle(const Offset(s / 2, s * 0.36), s * 0.62,
        Paint()..shader = ui.Gradient.radial(const Offset(s / 2, s * 0.36), s * 0.62, [p.accentGlow.withValues(alpha: 0.75), p.accentGlow.withValues(alpha: 0)]));
    c.save();
    c.translate(s * 0.1, s * 0.13);
    KeeperPainter(
      pose: KeeperPose()..mood = 0.75..gazeX = 0.15..gazeY = -0.1,
      body: p.accent, bodyLit: p.accentGlow, bodyDeep: p.accentDeep, eye: p.eye, ink: p.face, shadow: p.shadow,
    ).paint(c, const Size(s * 0.8, s * 0.8));
    c.restore();
    final img = await rec.endRecording().toImage(s.toInt(), s.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('assets/brand/icon_1024.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
