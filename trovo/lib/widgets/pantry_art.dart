import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../search.dart' show normalize;
import '../theme.dart';

/// Stile "dispensa illustrata": contorno a china, colori piatti come acquerello.
/// Ogni oggetto diventa un contenitore vero: barattolo, bottiglia, scatoletta,
/// scatola, cesto, sacchetto. Si vede cosa c'è dentro (chicchi, pasta, legumi…).

enum Vessel { jar, bottle, can, box, basket, bag, generic }

enum Fill { grains, powder, pasta, beans, chunks, liquid, leaves, none }

class VesselStyle {
  const VesselStyle(this.vessel, this.color, this.fill);
  final Vessel vessel;
  final Color color;
  final Fill fill;
}

const _rules = <(List<String>, VesselStyle)>[
  // Barattoli con il contenuto in vista.
  (['pasta', 'spaghett', 'penn', 'fusill', 'rigaton', 'maccheron', 'farfall', 'tagliatell'], VesselStyle(Vessel.jar, Color(0xFFE9C46A), Fill.pasta)),
  (['riso', 'rice', 'basmati', 'cous'], VesselStyle(Vessel.jar, Color(0xFFF5F0E3), Fill.grains)),
  (['farin', 'flour', 'amido', 'lievit'], VesselStyle(Vessel.jar, Color(0xFFFBF7EE), Fill.powder)),
  (['zucchero', 'sugar'], VesselStyle(Vessel.jar, Color(0xFFFFFFFF), Fill.grains)),
  (['sale', 'salt'], VesselStyle(Vessel.jar, Color(0xFFF7F7F4), Fill.grains)),
  (['cec', 'chickpea'], VesselStyle(Vessel.jar, Color(0xFFD9B57A), Fill.beans)),
  (['fagiol', 'bean'], VesselStyle(Vessel.jar, Color(0xFF9B3B32), Fill.beans)),
  (['lenticch', 'lentil', 'legum', 'pisell'], VesselStyle(Vessel.jar, Color(0xFFA0623A), Fill.grains)),
  (['caff', 'coffee', 'cacao', 'cocoa'], VesselStyle(Vessel.jar, Color(0xFF4B2E1E), Fill.powder)),
  (['te', 'tea', 'tisan', 'camomill', 'origan', 'basilic', 'erbe'], VesselStyle(Vessel.jar, Color(0xFF7D9A4B), Fill.leaves)),
  (['spezi', 'pepe', 'paprika', 'curry', 'peperoncin', 'cannell'], VesselStyle(Vessel.jar, Color(0xFFC1561B), Fill.powder)),
  (['cereal', 'muesli', 'avena', 'granola', 'cornflake'], VesselStyle(Vessel.jar, Color(0xFFE2B04A), Fill.chunks)),
  (['biscott', 'cookie', 'frollin'], VesselStyle(Vessel.jar, Color(0xFFD39A55), Fill.chunks)),
  (['cioccolat', 'chocolate', 'nutella'], VesselStyle(Vessel.jar, Color(0xFF5C3A21), Fill.chunks)),
  (['mandorl', 'noc', 'nut', 'pistacch', 'arachid', 'frutta secca'], VesselStyle(Vessel.jar, Color(0xFFA97142), Fill.chunks)),
  (['marmellat', 'confettur', 'miel', 'honey', 'jam'], VesselStyle(Vessel.jar, Color(0xFFD9822B), Fill.liquid)),
  (['aglio', 'garlic'], VesselStyle(Vessel.basket, Color(0xFFF2EBDD), Fill.chunks)),
  (['candel', 'candle'], VesselStyle(Vessel.jar, Color(0xFFF3E6C8), Fill.none)),
  // Bottiglie.
  (['olio', 'oil'], VesselStyle(Vessel.bottle, Color(0xFFC9B227), Fill.liquid)),
  (['acet', 'vinegar', 'soia', 'soy'], VesselStyle(Vessel.bottle, Color(0xFF5C1F1F), Fill.liquid)),
  (['vino', 'wine'], VesselStyle(Vessel.bottle, Color(0xFF6D1A36), Fill.liquid)),
  (['prosecc', 'spumant'], VesselStyle(Vessel.bottle, Color(0xFFE9D98B), Fill.liquid)),
  (['birr', 'beer'], VesselStyle(Vessel.bottle, Color(0xFFD9A13B), Fill.liquid)),
  (['acqua', 'water'], VesselStyle(Vessel.bottle, Color(0xFFCFE6F2), Fill.liquid)),
  (['passat', 'pomarol', 'sugo', 'salsa', 'ketchup', 'sauce'], VesselStyle(Vessel.bottle, Color(0xFFC0392B), Fill.liquid)),
  (['latt', 'milk', 'panna'], VesselStyle(Vessel.bottle, Color(0xFFFBFBF7), Fill.liquid)),
  (['succ', 'juice', 'aranciata', 'bibit', 'cola'], VesselStyle(Vessel.bottle, Color(0xFFEE9B2F), Fill.liquid)),
  (['detersiv', 'shampoo', 'sapon', 'ammorbident', 'candeggin'], VesselStyle(Vessel.bottle, Color(0xFF4FA3C7), Fill.liquid)),
  // Scatolette.
  (['tonn', 'tuna', 'sgombr', 'sardin', 'pelat', 'scatolett', 'lattin', 'carne', 'gatto', 'cane', 'croccantin'], VesselStyle(Vessel.can, Color(0xFF3C6E91), Fill.none)),
  // Scatole.
  (['medicin', 'farmac', 'pastigl', 'cerott', 'pill', 'pellicol', 'alluminio', 'cracker', 'grissin', 'fett', 'pile', 'batteri', 'lampadin', 'scatol', 'box', 'gioch', 'cavi', 'caricator'], VesselStyle(Vessel.box, Color(0xFFE6D3B3), Fill.none)),
  // Cesti di vimini.
  (['asciugaman', 'coper', 'lenzuol', 'vestit', 'maglion', 'calzin', 'mutand', 'patat', 'cipoll', 'frutta', 'verdur', 'pane', 'spugn', 'stracc', 'addobb', 'foto', 'libr'], VesselStyle(Vessel.basket, Color(0xFFD7B98E), Fill.none)),
  // Sacchetti.
  (['sacch', 'patatin', 'chips', 'bag'], VesselStyle(Vessel.bag, Color(0xFFE8D5B5), Fill.none)),
];

/// Che contenitore disegnare per un oggetto, dal suo nome.
VesselStyle vesselFor(Item item) {
  final words = normalize(item.name).split(' ');
  for (final (keys, style) in _rules) {
    for (final w in words) {
      for (final k in keys) {
        if (w == k || (k.length >= 3 && w.startsWith(k))) return style;
      }
    }
  }
  return const VesselStyle(Vessel.generic, Color(0xFFEFE4D0), Fill.none);
}

/// Un oggetto disegnato come contenitore, con l'emoji sull'etichetta.
class VesselView extends StatelessWidget {
  const VesselView({super.key, required this.item, required this.size, this.glow = 0, this.faded = 0});

  final Item item;

  /// Altezza del contenitore.
  final double size;
  final double glow;

  /// 0 = davanti, 1 = molto dietro (più chiaro).
  final double faded;

  @override
  Widget build(BuildContext context) {
    final style = vesselFor(item);
    final w = size * _aspect(style.vessel);
    return SizedBox(
      width: w,
      height: size,
      child: CustomPaint(
        painter: VesselPainter(style: style, emoji: item.emoji, glow: glow, faded: faded),
      ),
    );
  }

  static double _aspect(Vessel v) => switch (v) {
        Vessel.jar => 0.78,
        Vessel.bottle => 0.46,
        Vessel.can => 0.82,
        Vessel.box => 0.8,
        Vessel.basket => 1.15,
        Vessel.bag => 0.78,
        Vessel.generic => 0.86,
      };

  static double widthFor(Item item, double size) => size * _aspect(vesselFor(item).vessel);
}

class VesselPainter extends CustomPainter {
  VesselPainter({required this.style, required this.emoji, this.glow = 0, this.faded = 0});

  final VesselStyle style;
  final String emoji;
  final double glow;
  final double faded;

  Color _soft(Color c) => Color.lerp(c, PaperColors.wall, faded * 0.55)!;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = _soft(PaperColors.ink)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, size.height * 0.035)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;

    // Ombra sul ripiano.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h - 1), width: w * 0.95, height: h * 0.08),
      Paint()..color = PaperColors.ink.withValues(alpha: 0.10 * (1 - faded)),
    );

    if (glow > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius((Offset.zero & size).inflate(4), Radius.circular(w * 0.2)),
        Paint()
          ..color = TrovoColors.found.withValues(alpha: 0.55 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + 8 * glow),
      );
    }

    switch (style.vessel) {
      case Vessel.jar:
        _jar(canvas, size, ink);
      case Vessel.bottle:
        _bottle(canvas, size, ink);
      case Vessel.can:
        _can(canvas, size, ink);
      case Vessel.box:
        _box(canvas, size, ink);
      case Vessel.basket:
        _basket(canvas, size, ink);
      case Vessel.bag:
        _bag(canvas, size, ink);
      case Vessel.generic:
        _box(canvas, size, ink);
    }

    if (glow > 0) {
      ink
        ..color = TrovoColors.found
        ..strokeWidth = ink.strokeWidth + 1.5 * glow;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h).deflate(1), Radius.circular(w * 0.18)),
        ink,
      );
    }
  }

  /// Etichetta tonda di carta con l'emoji.
  void _label(Canvas canvas, Offset c, double r, Paint ink) {
    canvas.drawCircle(c, r, Paint()..color = _soft(const Color(0xFFFFFCF4)));
    canvas.drawCircle(c, r, ink..strokeWidth = ink.strokeWidth * 0.8);
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: r * 1.25, height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    if (faded > 0) {
      canvas.saveLayer(
        Rect.fromCircle(center: c, radius: r),
        Paint()..color = Colors.white.withValues(alpha: 1 - faded * 0.5),
      );
    }
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    if (faded > 0) canvas.restore();
    canvas.restore();
  }

  void _contents(Canvas canvas, Rect r, Path clip) {
    canvas.save();
    canvas.clipPath(clip);
    final base = _soft(style.color);
    canvas.drawRect(r, Paint()..color = base);
    final dark = _soft(Color.lerp(style.color, PaperColors.ink, 0.35)!);
    final p = Paint()..color = dark;
    final rnd = math.Random(style.color.toARGB32() ^ r.width.round());
    switch (style.fill) {
      case Fill.grains:
        for (var i = 0; i < (r.width * r.height / 22).clamp(6, 90); i++) {
          canvas.drawCircle(Offset(r.left + rnd.nextDouble() * r.width, r.top + rnd.nextDouble() * r.height), 0.8, p);
        }
      case Fill.powder:
        // Polvere: solo una riga di superficie.
        canvas.drawLine(Offset(r.left, r.top + 1), Offset(r.right, r.top + 1), p..strokeWidth = 1);
      case Fill.pasta:
        final s = Paint()
          ..color = dark
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < (r.width * r.height / 30).clamp(5, 60); i++) {
          final o = Offset(r.left + rnd.nextDouble() * r.width, r.top + rnd.nextDouble() * r.height);
          final a = rnd.nextDouble() * math.pi;
          canvas.drawLine(o, o + Offset(math.cos(a) * 4, math.sin(a) * 4), s);
        }
      case Fill.beans:
        final s = Paint()
          ..color = dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9;
        for (var i = 0; i < (r.width * r.height / 26).clamp(5, 60); i++) {
          final o = Offset(r.left + rnd.nextDouble() * r.width, r.top + rnd.nextDouble() * r.height);
          canvas.drawOval(Rect.fromCenter(center: o, width: 4, height: 3), s);
        }
      case Fill.chunks:
        final s = Paint()
          ..color = dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9;
        for (var i = 0; i < (r.width * r.height / 40).clamp(4, 40); i++) {
          final o = Offset(r.left + rnd.nextDouble() * r.width, r.top + rnd.nextDouble() * r.height);
          canvas.drawRect(Rect.fromCenter(center: o, width: 4.5, height: 4), s);
        }
      case Fill.leaves:
        for (var i = 0; i < (r.width * r.height / 26).clamp(5, 60); i++) {
          final o = Offset(r.left + rnd.nextDouble() * r.width, r.top + rnd.nextDouble() * r.height);
          canvas.drawOval(Rect.fromCenter(center: o, width: 3.5, height: 1.8), p);
        }
      case Fill.liquid:
        canvas.drawRect(
          Rect.fromLTWH(r.left + r.width * 0.15, r.top + 2, r.width * 0.12, r.height - 4),
          Paint()..color = Colors.white.withValues(alpha: 0.25 * (1 - faded)),
        );
      case Fill.none:
        break;
    }
    canvas.restore();
  }

  void _glassBody(Canvas canvas, Path body) {
    canvas.drawPath(body, Paint()..color = _soft(const Color(0xFFEAF1F1)).withValues(alpha: 0.85));
  }

  void _glassShine(Canvas canvas, Rect r) {
    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.7 * (1 - faded))
      ..strokeWidth = math.max(1.2, r.width * 0.05)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(r.left + r.width * 0.16, r.top + r.height * 0.18), Offset(r.left + r.width * 0.16, r.top + r.height * 0.5), shine);
  }

  void _jar(Canvas canvas, Size size, Paint ink) {
    final w = size.width;
    final h = size.height;
    final lidH = h * 0.14;
    final body = Rect.fromLTWH(w * 0.04, lidH * 0.9, w * 0.92, h - lidH * 0.9 - 2);
    final bodyPath = Path()..addRRect(RRect.fromRectAndRadius(body, Radius.circular(w * 0.16)));
    _glassBody(canvas, bodyPath);
    if (style.fill != Fill.none) {
      final level = body.top + body.height * 0.30;
      _contents(canvas, Rect.fromLTRB(body.left, level, body.right, body.bottom), bodyPath);
    }
    _glassShine(canvas, body);
    canvas.drawPath(bodyPath, ink);
    // Coperchio.
    final lid = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.12, 0, w * 0.76, lidH), Radius.circular(lidH * 0.35));
    canvas.drawRRect(lid, Paint()..color = _soft(const Color(0xFFD4A373)));
    canvas.drawRRect(lid, ink);
    _label(canvas, Offset(w / 2, body.top + body.height * 0.55), math.min(w, h) * 0.24, ink);
  }

  void _bottle(Canvas canvas, Size size, Paint ink) {
    final w = size.width;
    final h = size.height;
    final neckW = w * 0.38;
    final path = Path()
      ..moveTo(w / 2 - neckW / 2, h * 0.08)
      ..lineTo(w / 2 - neckW / 2, h * 0.26)
      ..quadraticBezierTo(w * 0.04, h * 0.32, w * 0.04, h * 0.42)
      ..lineTo(w * 0.04, h - 4)
      ..quadraticBezierTo(w * 0.04, h - 1, w * 0.15, h - 1)
      ..lineTo(w * 0.85, h - 1)
      ..quadraticBezierTo(w * 0.96, h - 1, w * 0.96, h - 4)
      ..lineTo(w * 0.96, h * 0.42)
      ..quadraticBezierTo(w * 0.96, h * 0.32, w / 2 + neckW / 2, h * 0.26)
      ..lineTo(w / 2 + neckW / 2, h * 0.08)
      ..close();
    _glassBody(canvas, path);
    _contents(canvas, Rect.fromLTRB(0, h * 0.38, w, h), path);
    _glassShine(canvas, Rect.fromLTWH(w * 0.04, h * 0.42, w * 0.92, h * 0.5));
    canvas.drawPath(path, ink);
    // Tappo.
    final cap = Rect.fromLTWH(w / 2 - neckW / 2 - 1, 0, neckW + 2, h * 0.1);
    canvas.drawRect(cap, Paint()..color = _soft(const Color(0xFF8C5A3C)));
    canvas.drawRect(cap, ink);
    _label(canvas, Offset(w / 2, h * 0.68), w * 0.36, ink);
  }

  void _can(Canvas canvas, Size size, Paint ink) {
    final w = size.width;
    final h = size.height;
    final body = Rect.fromLTWH(w * 0.05, h * 0.42, w * 0.9, h * 0.58 - 1);
    final rr = RRect.fromRectAndRadius(body, Radius.circular(w * 0.08));
    canvas.drawRRect(rr, Paint()..color = _soft(const Color(0xFFD8DDE2)));
    // Fascia colorata dell'etichetta.
    final band = Rect.fromLTWH(body.left, body.top + body.height * 0.2, body.width, body.height * 0.6);
    canvas.drawRect(band, Paint()..color = _soft(style.color));
    canvas.drawRRect(rr, ink);
    canvas.drawLine(band.topLeft, band.topRight, ink);
    canvas.drawLine(band.bottomLeft, band.bottomRight, ink);
    _label(canvas, band.center, math.min(band.height * 0.42, w * 0.26), ink);
  }

  void _box(Canvas canvas, Size size, Paint ink) {
    final w = size.width;
    final h = size.height;
    final body = Rect.fromLTWH(w * 0.04, h * 0.14, w * 0.92, h * 0.86 - 1);
    canvas.drawRect(body, Paint()..color = _soft(style.color));
    // Lembo superiore.
    final flap = Path()
      ..moveTo(body.left, body.top)
      ..lineTo(body.left + w * 0.12, 1)
      ..lineTo(body.right - w * 0.12, 1)
      ..lineTo(body.right, body.top)
      ..close();
    canvas.drawPath(flap, Paint()..color = _soft(Color.lerp(style.color, Colors.white, 0.3)!));
    canvas.drawPath(flap, ink);
    canvas.drawRect(body, ink);
    _label(canvas, body.center, math.min(w, h) * 0.26, ink);
  }

  void _basket(Canvas canvas, Size size, Paint ink) {
    final w = size.width;
    final h = size.height;
    final top = h * 0.3;
    final body = Path()
      ..moveTo(w * 0.02, top)
      ..lineTo(w * 0.98, top)
      ..lineTo(w * 0.9, h - 1)
      ..lineTo(w * 0.1, h - 1)
      ..close();
    // Quello che spunta dal cesto.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.14, top * 0.25, w * 0.72, top), Radius.circular(top * 0.5)),
      Paint()..color = _soft(Color.lerp(style.color, Colors.white, 0.45)!),
    );
    canvas.drawPath(body, Paint()..color = _soft(const Color(0xFFD9B98A)));
    // Intreccio del vimini.
    canvas.save();
    canvas.clipPath(body);
    final weave = Paint()
      ..color = _soft(const Color(0xFF9C7A4E))
      ..strokeWidth = 1;
    for (var y = top + 4; y < h; y += 5) {
      for (var x = 0.0; x < w; x += 7) {
        final o = (y ~/ 5).isEven ? 0.0 : 3.5;
        canvas.drawLine(Offset(x + o, y), Offset(x + o + 4, y + 2), weave);
      }
    }
    canvas.restore();
    canvas.drawPath(body, ink);
    canvas.drawLine(Offset(w * 0.02, top), Offset(w * 0.98, top), ink..strokeWidth = ink.strokeWidth * 1.3);
    _label(canvas, Offset(w / 2, top + (h - top) * 0.5), math.min(w, h - top) * 0.3, ink);
  }

  void _bag(Canvas canvas, Size size, Paint ink) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.12, h * 0.1)
      ..lineTo(w * 0.88, h * 0.1)
      ..lineTo(w * 0.96, h - 1)
      ..lineTo(w * 0.04, h - 1)
      ..close();
    canvas.drawPath(path, Paint()..color = _soft(style.color));
    canvas.drawPath(path, ink);
    canvas.drawLine(Offset(w * 0.12, h * 0.2), Offset(w * 0.88, h * 0.2), ink..strokeWidth = ink.strokeWidth * 0.7);
    _label(canvas, Offset(w / 2, h * 0.58), math.min(w, h) * 0.28, ink);
  }

  @override
  bool shouldRepaint(VesselPainter old) =>
      old.glow != glow || old.faded != faded || old.emoji != emoji || old.style.color != style.color || old.style.vessel != style.vessel;
}
