import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Carte da parati delle stanze, disegnate dall'app.
enum Wallpaper { flowers, dots, tiles, bricks, stripes, beadboard, plain }

Wallpaper wallpaperFrom(Object? v) =>
    Wallpaper.values.firstWhere((w) => w.name == v, orElse: () => Wallpaper.plain);

/// La carta della stanza: quella scelta, oppure una adatta alla stanza.
Wallpaper wallpaperOf(Room room) {
  if (room.wallpaper != null) return wallpaperFrom(room.wallpaper);
  final n = room.name.toLowerCase();
  if (room.emoji == '🛁' || n.contains('bagn') || n.contains('bath')) return Wallpaper.tiles;
  if (['🚗', '🧰', '🍷'].contains(room.emoji) || n.contains('garage') || n.contains('cantin') || n.contains('cellar')) {
    return Wallpaper.bricks;
  }
  if (room.emoji == '🛏️' || n.contains('camer') || n.contains('bed')) return Wallpaper.stripes;
  if (['🥫', '🍳'].contains(room.emoji) || n.contains('dispens') || n.contains('cucin') || n.contains('pantry') || n.contains('kitchen')) {
    return Wallpaper.flowers;
  }
  return Wallpaper.dots;
}

/// Sfondo della stanza. [veil] schiarisce il disegno (per leggere meglio i testi sopra).
class WallpaperBackground extends StatelessWidget {
  const WallpaperBackground({super.key, required this.wallpaper, required this.child, this.veil = 0});
  final Wallpaper wallpaper;
  final Widget child;
  final double veil;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(child: CustomPaint(painter: WallpaperPainter(wallpaper))),
        ),
        if (veil > 0) Positioned.fill(child: ColoredBox(color: TrovoColors.background.withValues(alpha: veil))),
        child,
      ],
    );
  }
}

class WallpaperPainter extends CustomPainter {
  WallpaperPainter(this.wallpaper, {this.scale = 1});
  final Wallpaper wallpaper;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    switch (wallpaper) {
      case Wallpaper.flowers:
        _flowers(canvas, size);
      case Wallpaper.dots:
        _dots(canvas, size);
      case Wallpaper.tiles:
        _tiles(canvas, size);
      case Wallpaper.bricks:
        _bricks(canvas, size);
      case Wallpaper.stripes:
        _stripes(canvas, size);
      case Wallpaper.beadboard:
        _beadboard(canvas, size);
      case Wallpaper.plain:
        canvas.drawRect(Offset.zero & size, Paint()..color = TrovoColors.background);
    }
    canvas.restore();
  }

  /// Fiorellini e rametti su carta crema.
  void _flowers(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF8EEDF));
    final cell = 74.0 * scale;
    final rnd = math.Random(11);
    final dot = Paint()..color = const Color(0xFFDDBFA4);
    final stem = Paint()
      ..color = const Color(0xFF8AA37A)
      ..strokeWidth = 1.3 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final leaf = Paint()..color = const Color(0xFFA3B98F);
    final petal = Paint()..color = const Color(0xFFCB6D57);
    final center = Paint()..color = const Color(0xFFE9B44C);
    for (var gy = -1; gy * cell < size.height + cell; gy++) {
      for (var gx = -1; gx * cell < size.width + cell; gx++) {
        final ox = gx * cell + (gy.isOdd ? cell / 2 : 0) + rnd.nextDouble() * 14 * scale;
        final oy = gy * cell + rnd.nextDouble() * 14 * scale;
        // Rametto.
        final base = Offset(ox + cell * 0.3, oy + cell * 0.75);
        final tip = base + Offset(rnd.nextDouble() * 8 - 4, -cell * 0.38);
        canvas.drawLine(base, tip, stem);
        for (var k = 0; k < 3; k++) {
          final p = Offset.lerp(base, tip, 0.25 + k * 0.25)!;
          final side = k.isEven ? 1 : -1;
          canvas.save();
          canvas.translate(p.dx + side * 3.5 * scale, p.dy);
          canvas.rotate(side * 0.7);
          canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 7 * scale, height: 3 * scale), leaf);
          canvas.restore();
        }
        // Fiorellino.
        final f = Offset(ox + cell * 0.72, oy + cell * 0.32);
        for (var k = 0; k < 5; k++) {
          final a = k * 2 * math.pi / 5;
          canvas.drawCircle(f + Offset(math.cos(a), math.sin(a)) * 3.4 * scale, 2.4 * scale, petal);
        }
        canvas.drawCircle(f, 1.6 * scale, center);
        // Puntini sparsi.
        canvas.drawCircle(Offset(ox + cell * 0.12, oy + cell * 0.2), 1.3 * scale, dot);
        canvas.drawCircle(Offset(ox + cell * 0.55, oy + cell * 0.62), 1.1 * scale, dot);
      }
    }
  }

  void _dots(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF5EEE2));
    final p = Paint()..color = const Color(0xFFD7C3A8);
    final step = 22.0 * scale;
    for (var y = 0.0; y < size.height + step; y += step) {
      for (var x = ((y ~/ step).isOdd ? step / 2 : 0.0); x < size.width + step; x += step) {
        canvas.drawCircle(Offset(x, y), 1.6 * scale, p);
      }
    }
  }

  void _tiles(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEFF5F3));
    final step = 30.0 * scale;
    final grout = Paint()
      ..color = const Color(0xFFC9D6D2)
      ..strokeWidth = 1.5 * scale;
    final shine = Paint()..color = Colors.white.withValues(alpha: 0.7);
    for (var y = 0.0; y < size.height + step; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grout);
      for (var x = 0.0; x < size.width + step; x += step) {
        canvas.drawRect(Rect.fromLTWH(x + 4 * scale, y + 4 * scale, 6 * scale, 2 * scale), shine);
      }
    }
    for (var x = 0.0; x < size.width + step; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grout);
    }
  }

  void _bricks(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE9DCCF));
    final bw = 46.0 * scale;
    final bh = 18.0 * scale;
    final rnd = math.Random(5);
    const tones = [Color(0xFFD7A58B), Color(0xFFCB967B), Color(0xFFDDB29B), Color(0xFFC88E73)];
    for (var row = 0; row * bh < size.height + bh; row++) {
      final off = row.isOdd ? -bw / 2 : 0.0;
      for (var x = off; x < size.width + bw; x += bw) {
        final r = Rect.fromLTWH(x + 1.5 * scale, row * bh + 1.5 * scale, bw - 3 * scale, bh - 3 * scale);
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, Radius.circular(2 * scale)),
          Paint()..color = tones[rnd.nextInt(tones.length)].withValues(alpha: 0.75),
        );
      }
    }
  }

  void _stripes(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF6EEF0));
    final w = 18.0 * scale;
    final a = Paint()..color = const Color(0xFFEBD9DE);
    final line = Paint()
      ..color = const Color(0xFFDCC2C9)
      ..strokeWidth = 1 * scale;
    for (var x = 0.0; x < size.width + w; x += 2 * w) {
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), a);
      canvas.drawLine(Offset(x + w * 1.5, 0), Offset(x + w * 1.5, size.height), line);
    }
  }

  void _beadboard(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF7F1E6));
    final w = 16.0 * scale;
    final groove = Paint()
      ..color = const Color(0xFFDFD3BF)
      ..strokeWidth = 1.4 * scale;
    final light = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1 * scale;
    for (var x = 0.0; x < size.width + w; x += w) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), groove);
      canvas.drawLine(Offset(x + 1.6 * scale, 0), Offset(x + 1.6 * scale, size.height), light);
    }
  }

  @override
  bool shouldRepaint(WallpaperPainter old) => old.wallpaper != wallpaper || old.scale != scale;
}

/// Quadratino d'anteprima per scegliere la carta da parati.
class WallpaperSwatch extends StatelessWidget {
  const WallpaperSwatch({super.key, required this.wallpaper, required this.selected, required this.onTap, required this.label});
  final Wallpaper wallpaper;
  final bool selected;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? TrovoColors.primary : PaperColors.ink.withValues(alpha: 0.7), width: selected ? 3 : 1.4),
              boxShadow: PaperColors.printShadow(2),
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(painter: WallpaperPainter(wallpaper, scale: 0.8)),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
