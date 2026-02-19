import 'dart:io';
import 'dart:math';
import 'package:image/image.dart';

void main() {
  const width = 1024;
  const height = 1024;
  const double scale = width / 192.0;

  // Colors
  final primary = ColorRgba8(
    0x4b,
    0x7c,
    0x5a,
    0xff,
  ); // #4b7c5a (Main Green - consistent)

  // Light Mode Colors
  final accentLight = ColorRgba8(0x2c, 0x3e, 0x50, 0xff); // #2C3E50 (Dark Blue)
  final white = ColorRgba8(0xff, 0xff, 0xff, 0xff);

  // Dark Mode Colors (from SVG media query)
  final accentDark = ColorRgba8(0x9c, 0xa3, 0xaf, 0xff); // #9ca3af (Light Gray)
  final dotDark = ColorRgba8(0xff, 0xff, 0xff, 0xff); // #FFFFFF (White)

  // --- 1. App Icon (White Background) ---
  final appIcon = Image(width: width, height: height);
  // Fill white
  for (var p in appIcon) {
    p.r = 255;
    p.g = 255;
    p.b = 255;
    p.a = 255;
  }

  drawLogo(
    appIcon,
    primary,
    accentLight,
    accentLight,
    scale,
  ); // Dot is accent color in light mode logic for simplicity? No, svg says dot-color #2C3E50 (accent)

  final f1 = File('assets/images/app_icon.png');
  f1.createSync(recursive: true);
  f1.writeAsBytesSync(encodePng(appIcon));
  print('Generated ${f1.path}');

  // --- 2. Splash Logo Light (Transparent Background) ---
  final splashLogo = Image(width: width, height: height);
  clearImage(splashLogo);

  drawLogo(splashLogo, primary, accentLight, accentLight, scale);

  final f2 = File('assets/images/splash_logo.png');
  f2.createSync(recursive: true);
  f2.writeAsBytesSync(encodePng(splashLogo));
  print('Generated ${f2.path}');

  // --- 3. Splash Logo Dark (Transparent Background) ---
  final splashLogoDark = Image(width: width, height: height);
  clearImage(splashLogoDark);

  // Use Dark Mode accent and Dot color
  drawLogo(splashLogoDark, primary, accentDark, dotDark, scale);

  final f3 = File('assets/images/splash_logo_dark.png');
  f3.createSync(recursive: true);
  f3.writeAsBytesSync(encodePng(splashLogoDark));
  print('Generated ${f3.path}');
}

void clearImage(Image img) {
  for (var p in img) {
    p.r = 0;
    p.g = 0;
    p.b = 0;
    p.a = 0;
  }
}

void drawLogo(
  Image img,
  Color primary,
  Color accent,
  Color dotColor,
  double scale,
) {
  // Helper for coordinates
  int s(num v) => (v * scale).round();

  // Coordinates
  // Bars
  // Left & Right use accent color
  final rects = [
    // Left: Accent
    {'x': 69, 'y': 72, 'w': 10, 'h': 32, 'r': 5, 'c': accent},
    // Center: Primary
    {'x': 91, 'y': 48, 'w': 12, 'h': 56, 'r': 6, 'c': primary},
    // Right: Accent
    {'x': 115, 'y': 72, 'w': 10, 'h': 32, 'r': 5, 'c': accent},
  ];

  // Bowl
  final bowlCx = 96.0 * scale;
  final bowlCy = 112.0 * scale;
  final bowlThickness = 4.0 * scale;
  final bowlRadiusCenter = 46.0 * scale;
  final bowlInnerR2 = pow(bowlRadiusCenter - bowlThickness / 2, 2);
  final bowlOuterR2 = pow(bowlRadiusCenter + bowlThickness / 2, 2);

  // Dot
  final dotCx = 96.0 * scale;
  final dotCy = 140.0 * scale;
  final dotR2 = pow(3.0 * scale, 2);

  // Precompute rect bounds
  final scaledRects = rects.map((r) {
    return {
      'x1': (r['x'] as int) * scale,
      'y1': (r['y'] as int) * scale,
      'x2': ((r['x'] as int) + (r['w'] as int)) * scale,
      'y2': ((r['y'] as int) + (r['h'] as int)) * scale,
      'rad': (r['r'] as int) * scale,
      'c': r['c'] as Color, // This is technically Color, need cast later
    };
  }).toList();

  for (var p in img) {
    final x = p.x;
    final y = p.y;

    // 1. Draw Rects
    for (var r in scaledRects) {
      final x1 = r['x1'] as double;
      final y1 = r['y1'] as double;
      final x2 = r['x2'] as double;
      final y2 = r['y2'] as double;
      final rad = r['rad'] as double;
      final c = r['c'] as ColorRgba8;

      if (x >= x1 && x <= x2 && y >= y1 && y <= y2) {
        // Optimized rounded rect check without sqrt for bounding box
        bool inside = true;
        // Check corners
        if (x < x1 + rad && y < y1 + rad) {
          if (pow(x - (x1 + rad), 2) + pow(y - (y1 + rad), 2) > pow(rad, 2)) {
            inside = false;
          }
        } else if (x > x2 - rad && y < y1 + rad) {
          if (pow(x - (x2 - rad), 2) + pow(y - (y1 + rad), 2) > pow(rad, 2)) {
            inside = false;
          }
        } else if (x < x1 + rad && y > y2 - rad) {
          if (pow(x - (x1 + rad), 2) + pow(y - (y2 - rad), 2) > pow(rad, 2)) {
            inside = false;
          }
        } else if (x > x2 - rad && y > y2 - rad) {
          if (pow(x - (x2 - rad), 2) + pow(y - (y2 - rad), 2) > pow(rad, 2)) {
            inside = false;
          }
        }

        if (inside) {
          p.r = c.r;
          p.g = c.g;
          p.b = c.b;
          p.a = c.a;
        }
      }
    }

    // 2. Draw Bowl
    if (y >= bowlCy) {
      final d2 = pow(x - bowlCx, 2) + pow(y - bowlCy, 2);
      if (d2 >= bowlInnerR2 && d2 <= bowlOuterR2) {
        final c = primary as ColorRgba8;
        p.r = c.r;
        p.g = c.g;
        p.b = c.b;
        p.a = c.a;
      }
    }

    // 3. Draw Dot (Use dotColor)
    final d2Dot = pow(x - dotCx, 2) + pow(y - dotCy, 2);
    if (d2Dot <= dotR2) {
      final c = dotColor as ColorRgba8;
      p.r = c.r;
      p.g = c.g;
      p.b = c.b;
      p.a = c.a;
    }
  }
}
