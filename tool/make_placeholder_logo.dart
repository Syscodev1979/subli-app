import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';

/// TODO_SUBLI: ideiglenes logó, piros kör fehér S betűvel.
/// A végleges logó ezt a fájlt és az ikonokat cseréli.
void main() {
  const size = 1024;
  final logo = Image(width: size, height: size, numChannels: 4);
  fill(logo, color: ColorRgba8(0, 0, 0, 0));
  fillCircle(
    logo,
    x: size ~/ 2,
    y: size ~/ 2,
    radius: 460,
    color: ColorRgb8(198, 40, 40),
  );
  _drawS(logo);
  File('assets/images/logo.png').writeAsBytesSync(encodePng(logo));
}

void _drawS(Image canvas) {
  const cx = 512.0;
  const radius = 168.0;
  const top = 512.0 - radius;
  const bottom = 512.0 + radius;
  const stroke = 42.0;
  final color = ColorRgb8(255, 255, 255);

  // Felső tál: bal szabad vég, felül át, a jobb oldalon le a középig.
  for (var degree = 175; degree <= 455; degree += 2) {
    final angle = degree * pi / 180;
    _stamp(
      canvas,
      cx + cos(angle) * radius,
      top + sin(angle) * radius,
      stroke,
      color,
    );
  }
  // Alsó tál: a középtől balra, alul át, jobb szabad vég.
  for (var degree = 265; degree >= -5; degree -= 2) {
    final angle = degree * pi / 180;
    _stamp(
      canvas,
      cx + cos(angle) * radius,
      bottom + sin(angle) * radius,
      stroke,
      color,
    );
  }
}

void _stamp(Image canvas, double x, double y, double radius, Color color) {
  fillCircle(
    canvas,
    x: x.round(),
    y: y.round(),
    radius: radius.round(),
    color: color,
  );
}
