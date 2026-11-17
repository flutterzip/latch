// Renders the keeper in its main poses to build/keeper_sheet.png.
// flutter test tool/render/keeper_sheet_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latch/config/palette.dart';
import 'package:latch/widgets/keeper/keeper_painter.dart';

void main() {
  test('keeper sheet', () async {
    for (final mode in ['light', 'dark']) {
      final pal = mode == 'light' ? Palette.light : Palette.dark;
      final poses = <KeeperPose>[
        KeeperPose(),
        KeeperPose()..gazeX = -0.85..gazeY = 0.95,
        KeeperPose()..gazeX = 0.85..gazeY = 0.95,
        KeeperPose()..cover = 1,
        KeeperPose()..cover = 1..peek = 1..gazeY = 0.9,
        KeeperPose()..shake = 8..mood = 0.1,
        KeeperPose()..happy = 1..hop = 20..mood = 1,
        KeeperPose()..wave = 1..swing = 0.6..mood = 0.7,
        KeeperPose()..lid = 0.6,
        KeeperPose()..mood = 1,
      ];
      const cell = 300.0;
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      canvas.drawRect(Rect.fromLTWH(0, 0, cell * 5, cell * 2), Paint()..color = pal.paper);
      for (var i = 0; i < poses.length; i++) {
        canvas.save();
        canvas.translate((i % 5) * cell, (i ~/ 5) * cell);
        KeeperPainter(pose: poses[i], body: pal.accent, bodyLit: pal.accentGlow, bodyDeep: pal.accentDeep, eye: pal.eye, ink: pal.face, shadow: pal.shadow)
            .paint(canvas, const Size(cell, cell));
        canvas.restore();
      }
      final img = await rec.endRecording().toImage((cell * 5).toInt(), (cell * 2).toInt());
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/keeper_$mode.png')..createSync(recursive: true)..writeAsBytesSync(bytes!.buffer.asUint8List());
    }
  });
}
