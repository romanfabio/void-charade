// Draws the logo, launcher icon and splash images into assets/branding/.
// It is a "test" only because Flutter's canvas (dart:ui) needs the Flutter
// engine; run it with:
//
//   flutter test tool/generate_branding_test.dart
//
// Then regenerate the platform icons / splash with:
//
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _ink = Color(0xFF14101F);
const _magenta = Color(0xFFFF3D9A);
const _orange = Color(0xFFFF8A3D);
const _cyan = Color(0xFF22D3EE);
const _violet = Color(0xFF7C4DFF);

/// Full-bleed background: magenta to violet with a warm glow.
void _paintBackground(Canvas canvas, double size) {
  final rect = Rect.fromLTWH(0, 0, size, size);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_magenta, _violet],
      ).createShader(rect),
  );
  canvas.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.9, 0.95),
        radius: 0.9,
        colors: [_orange.withValues(alpha: 0.65), _orange.withValues(alpha: 0)],
      ).createShader(rect),
  );
}

Path _sparkle(Offset c, double r) {
  final path = Path();
  for (var i = 0; i < 8; i++) {
    final radius = i.isEven ? r : r * 0.26;
    final angle = -math.pi / 2 + i * math.pi / 4;
    final p = Offset(c.dx + radius * math.cos(angle), c.dy + radius * math.sin(angle));
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

/// A tilted phone showing a big "?", with three sparkles. Designed in a
/// ~800 unit box centred on [center]; [scale] resizes it.
void _paintGlyph(Canvas canvas, Offset center, double scale) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(scale);

  canvas.save();
  canvas.rotate(-0.24);
  final body = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: 430, height: 700),
    const Radius.circular(84),
  );
  canvas.drawRRect(
    body.shift(const Offset(0, 30)),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 32),
  );
  canvas.drawRRect(body, Paint()..color = Colors.white);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 10), width: 374, height: 600),
      const Radius.circular(60),
    ),
    Paint()..color = _ink,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, -322), width: 90, height: 12),
      const Radius.circular(6),
    ),
    Paint()..color = const Color(0xFFD9D2EC),
  );

  final tp = TextPainter(
    text: TextSpan(
      text: '?',
      style: TextStyle(
        fontFamily: 'LilitaOne',
        fontSize: 470,
        height: 1,
        foreground: Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_orange, _magenta],
          ).createShader(
            Rect.fromCenter(center: const Offset(0, 10), width: 300, height: 420),
          ),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(-tp.width / 2, 10 - tp.height / 2));
  canvas.restore();

  canvas.drawPath(_sparkle(const Offset(-300, -335), 74), Paint()..color = _cyan);
  canvas.drawPath(_sparkle(const Offset(318, -215), 52), Paint()..color = _orange);
  canvas.drawPath(_sparkle(const Offset(300, 320), 62), Paint()..color = Colors.white);
  canvas.restore();
}

Future<void> _save(
  String name,
  int size,
  void Function(Canvas canvas, double size) paint,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
  paint(canvas, size.toDouble());
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  final file = File('assets/branding/$name')..createSync(recursive: true);
  file.writeAsBytesSync(bytes.buffer.asUint8List());
  stdout.writeln('$name  ${size}x$size  ${file.lengthSync()} bytes');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate branding images', () async {
    final font = FontLoader('LilitaOne')
      ..addFont(Future.value(
        ByteData.sublistView(File('assets/fonts/LilitaOne-Regular.ttf').readAsBytesSync()),
      ));
    await font.load();

    Offset mid(double s) => Offset(s / 2, s / 2);

    // Launcher icon: opaque, glyph fills most of the square.
    await _save('icon.png', 1024, (c, s) {
      _paintBackground(c, s);
      _paintGlyph(c, mid(s), 1.0);
    });
    // Android adaptive icon: the launcher crops to a circle, so keep the glyph
    // well inside the central ~60%.
    await _save('icon_background.png', 1024, _paintBackground);
    await _save('icon_foreground.png', 1024, (c, s) => _paintGlyph(c, mid(s), 0.80));
    // Splash screens (transparent; drawn over the app's dark background).
    await _save('splash_logo.png', 768, (c, s) => _paintGlyph(c, mid(s), 0.80));
    await _save('splash_logo_android12.png', 1152, (c, s) => _paintGlyph(c, mid(s), 0.72));
    // In-app logo (home header, about dialog).
    await _save('logo.png', 256, (c, s) => _paintGlyph(c, mid(s), 0.30));
  });
}
