import 'dart:io';

import 'package:image/image.dart';

/// Fehér hátterű, átlátszóság nélküli ikonok. A dev változatra DEV szalag kerül.
void main() {
  final bytes = File('assets/images/logo.png').readAsBytesSync();
  final logo = decodePng(bytes);
  if (logo == null) {
    stderr.writeln('A logó nem olvasható.');
    exit(1);
  }
  File('assets/images/app_icon.png')
      .writeAsBytesSync(encodePng(_icon(logo, badge: false)));
  File('assets/images/app_icon_dev.png')
      .writeAsBytesSync(encodePng(_icon(logo, badge: true)));
  File('assets/images/logo_splash.png')
      .writeAsBytesSync(encodePng(_splash(logo)));
}

Image _icon(Image logo, {required bool badge}) {
  const size = 1024;
  final canvas = Image(width: size, height: size, numChannels: 4);
  fill(canvas, color: ColorRgb8(255, 255, 255));
  final fitted = copyResize(
    logo,
    width: 860,
    height: 860,
    interpolation: Interpolation.average,
  );
  compositeImage(canvas, fitted, dstX: 82, dstY: 70);
  if (badge) {
    fillRect(
      canvas,
      x1: 0,
      y1: 860,
      x2: size - 1,
      y2: size - 1,
      color: ColorRgb8(0x6B, 0x1E, 0x2E),
    );
    final label = Image(width: 220, height: 64, numChannels: 4);
    fill(label, color: ColorRgb8(0x6B, 0x1E, 0x2E));
    drawString(
      label,
      'DEV',
      font: arial48,
      x: 58,
      y: 8,
      color: ColorRgb8(255, 255, 255),
    );
    final big = copyResize(label, width: 420, height: 120);
    compositeImage(canvas, big, dstX: 302, dstY: 880);
  }
  return canvas;
}

/// A fehér háttér átlátszó lesz, hogy a sötét indítóképernyőn a logó látszódjon.
Image _splash(Image logo) {
  final copy = logo.clone();
  for (final pixel in copy) {
    if (pixel.r > 245 && pixel.g > 245 && pixel.b > 245) {
      pixel.a = 0;
    }
  }
  return copy;
}
