import 'dart:io';

import 'package:image/image.dart';

/// A helyettesítő ikont méretezi az Android, iOS, macOS, Windows és web helyekre.
/// A dev mappa az DEV szalagos ikont kapja.
void main() {
  final prod = decodePng(File('assets/images/app_icon.png').readAsBytesSync());
  final dev = decodePng(File('assets/images/app_icon_dev.png').readAsBytesSync());
  if (prod == null || dev == null) {
    stderr.writeln('Az ikon nem olvasható. Előbb a make_launcher_icons fusson.');
    exit(1);
  }

  _installAndroid(prod, dev);
  _installIos(prod, dev);
  _installMacos(prod);
  _installWeb(prod);
  _installWindows(prod);
}

void _installAndroid(Image prod, Image dev) {
  const launcher = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };
  const foreground = {
    'mdpi': 108,
    'hdpi': 162,
    'xhdpi': 216,
    'xxhdpi': 324,
    'xxxhdpi': 432,
  };
  final roots = [
    'android/app/src/main/res',
    'android/app/src/prod/res',
    'android/app/src/dev/res',
  ];
  for (final root in roots) {
    final source = root.contains('/dev/') ? dev : prod;
    for (final entry in launcher.entries) {
      _write(
        '$root/mipmap-${entry.key}/ic_launcher.png',
        source,
        entry.value,
      );
    }
    for (final entry in foreground.entries) {
      _write(
        '$root/drawable-${entry.key}/ic_launcher_foreground.png',
        source,
        entry.value,
      );
    }
  }
}

void _installIos(Image prod, Image dev) {
  final catalogs = Directory('ios/Runner/Assets.xcassets')
      .listSync()
      .whereType<Directory>()
      .where((dir) => dir.path.contains('AppIcon'));
  for (final catalog in catalogs) {
    final source = catalog.path.contains('AppIcon-dev') ? dev : prod;
    for (final entity in catalog.listSync().whereType<File>()) {
      if (!entity.path.endsWith('.png')) continue;
      final side = _iosSide(entity.uri.pathSegments.last);
      if (side == null) continue;
      _write(entity.path, source, side);
    }
  }
}

int? _iosSide(String name) {
  final match = RegExp(
    r'(\d+(?:\.\d+)?)x\d+(?:\.\d+)?@(\d+)x',
  ).firstMatch(name);
  if (match == null) return null;
  final points = double.parse(match.group(1)!);
  final scale = int.parse(match.group(2)!);
  return (points * scale).round();
}

void _installMacos(Image prod) {
  final dir = Directory('macos/Runner/Assets.xcassets/AppIcon.appiconset');
  if (!dir.existsSync()) return;
  for (final entity in dir.listSync().whereType<File>()) {
    final match = RegExp(r'app_icon_(\d+)\.png$').firstMatch(entity.path);
    if (match == null) continue;
    _write(entity.path, prod, int.parse(match.group(1)!));
  }
}

void _installWeb(Image prod) {
  _write('web/favicon.png', prod, 32);
  _write('web/icons/Icon-192.png', prod, 192);
  _write('web/icons/Icon-512.png', prod, 512);
  _write('web/icons/Icon-maskable-192.png', prod, 192);
  _write('web/icons/Icon-maskable-512.png', prod, 512);
}

void _installWindows(Image prod) {
  final sizes = [16, 32, 48, 64, 128, 256];
  final images = [
    for (final side in sizes)
      copyResize(prod, width: side, height: side, interpolation: Interpolation.average),
  ];
  File('windows/runner/resources/app_icon.ico').writeAsBytesSync(
    IcoEncoder().encodeImages(images),
  );
}

void _write(String path, Image source, int side) {
  final file = File(path);
  if (!file.existsSync()) return;
  final resized = copyResize(
    source,
    width: side,
    height: side,
    interpolation: Interpolation.average,
  );
  file.writeAsBytesSync(encodePng(resized));
}
