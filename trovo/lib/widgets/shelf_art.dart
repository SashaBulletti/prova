import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Disegno degli scaffali in ferro: montanti forati, piani con il bordo colorato.

const _holeSpacing = 13.0;

/// Montante forato dello scaffale.
void paintUpright(Canvas canvas, Rect rect, {double holeOffset = 0}) {
  final r = RRect.fromRectAndRadius(rect, const Radius.circular(3));
  final paint = Paint()
    ..shader = const LinearGradient(
      colors: [TrovoColors.metalLight, TrovoColors.metal, TrovoColors.metalDark],
      stops: [0, 0.45, 1],
    ).createShader(rect);
  canvas.drawRRect(r, paint);

  // Fori del montante, come negli scaffali veri.
  final holePaint = Paint()..color = TrovoColors.background.withValues(alpha: 0.75);
  final hw = math.max(2.0, rect.width * 0.36);
  final hh = math.max(3.0, rect.width * 0.62);
  final start = rect.top + ((_holeSpacing - holeOffset % _holeSpacing) % _holeSpacing) + 3;
  for (var y = start; y < rect.bottom - hh - 1; y += _holeSpacing) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.center.dx - hw / 2, y, hw, hh),
        Radius.circular(hw / 2),
      ),
      holePaint,
    );
  }
}

/// Scaffale in miniatura (Home, risultati di ricerca, anteprima).
/// [slots]: per ogni piano, quali posti sono occupati (true) e quali liberi.
class MiniShelfPainter extends CustomPainter {
  MiniShelfPainter({
    required this.levelColors,
    required this.slots,
    this.highlightIndex,
    this.highlightPositions = const {},
    this.glow = 0,
  });

  final List<Color> levelColors;
  final List<List<bool>> slots;
  final int? highlightIndex;
  final Set<int> highlightPositions;
  final double glow;

  static const _blockHeights = [0.62, 0.78, 0.5, 0.7, 0.58];

  @override
  void paint(Canvas canvas, Size size) {
    final n = math.max(1, levelColors.length);
    final uw = (size.width * 0.075).clamp(4.0, 12.0);
    const top = 3.0;
    final feet = (size.height * 0.05).clamp(4.0, 10.0);
    final levelH = (size.height - top - feet) / n;
    final boardH = (levelH * 0.16).clamp(2.5, 9.0);
    final innerLeft = uw;
    final innerRight = size.width - uw;
    final innerW = innerRight - innerLeft;

    for (var i = 0; i < levelColors.length; i++) {
      final cellTop = top + i * levelH;
      final boardY = cellTop + levelH - boardH;
      final color = levelColors[i];
      final isHi = highlightIndex == i;

      if (isHi && glow > 0) {
        final glowRect = Rect.fromLTWH(innerLeft - 2, cellTop + 1, innerW + 4, levelH - 1);
        canvas.drawRRect(
          RRect.fromRectAndRadius(glowRect, const Radius.circular(4)),
          Paint()
            ..color = TrovoColors.found.withValues(alpha: 0.32 * glow)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + 6 * glow),
        );
      }

      // Un blocchetto per ogni posto occupato, al suo posto.
      final row = slots.length > i ? slots[i] : const <bool>[];
      if (row.isNotEmpty) {
        final colW = innerW / row.length;
        final blockW = colW * 0.72;
        for (var p = 0; p < row.length; p++) {
          if (!row[p]) continue;
          final h = (levelH - boardH) * _blockHeights[(p + i) % _blockHeights.length];
          final x = innerLeft + p * colW + (colW - blockW) / 2;
          final rect = Rect.fromLTWH(x, boardY - h, blockW, h);
          final hiBlock = isHi && (highlightPositions.isEmpty || highlightPositions.contains(p));
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(math.min(blockW * 0.22, 3))),
            Paint()
              ..color = (hiBlock ? Color.lerp(color, TrovoColors.found, glow)! : color)
                  .withValues(alpha: hiBlock ? 0.55 + 0.4 * glow : 0.55),
          );
        }
      }

      // Ripiano: bordo frontale colorato.
      final lip = Rect.fromLTWH(innerLeft - uw * 0.3, boardY, innerW + uw * 0.6, boardH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(lip, Radius.circular(boardH * 0.3)),
        Paint()..color = isHi ? Color.lerp(color, TrovoColors.found, glow)! : color,
      );
    }

    paintUpright(canvas, Rect.fromLTWH(0, 0, uw, size.height));
    paintUpright(canvas, Rect.fromLTWH(size.width - uw, 0, uw, size.height));
  }

  @override
  bool shouldRepaint(MiniShelfPainter old) =>
      old.glow != glow ||
      old.highlightIndex != highlightIndex ||
      old.levelColors.length != levelColors.length ||
      !_listEq(old.levelColors, levelColors) ||
      old.slots.length != slots.length ||
      !_slotsEq(old.slots, slots);
}

bool _slotsEq(List<List<bool>> a, List<List<bool>> b) {
  for (var i = 0; i < a.length; i++) {
    if (!_listEq(a[i], b[i])) return false;
  }
  return true;
}

/// Occupazione dei posti di uno scaffale, per il disegno in miniatura.
List<List<bool>> shelfSlots(Iterable<List<String?>> levels) =>
    [for (final l in levels) [for (final s in l) s != null]];

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Un piano dello scaffale grande, con montanti, ripiano e bordo colorato.
class LevelFramePainter extends CustomPainter {
  LevelFramePainter({
    required this.color,
    required this.yOffset,
    this.highlight = 0,
    this.pressed = 0,
  });

  final Color color;

  /// Posizione verticale del piano: serve per allineare i fori dei montanti.
  final double yOffset;
  final double highlight;
  final double pressed;

  static const uprightWidth = 16.0;
  static const boardTop = 0.78; // in proporzione all'altezza

  @override
  void paint(Canvas canvas, Size size) {
    const uw = uprightWidth;
    final boardY = size.height * boardTop;
    final innerRect = Rect.fromLTRB(uw, 0, size.width - uw, boardY);

    // Sfondo del vano: leggermente più chiaro, così sembra profondo.
    canvas.drawRect(
      innerRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(TrovoColors.background, color, 0.03 + pressed * 0.05)!,
            Color.lerp(TrovoColors.surface, color, 0.06 + pressed * 0.08)!,
          ],
        ).createShader(innerRect),
    );

    if (highlight > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(innerRect.deflate(2), const Radius.circular(10)),
        Paint()
          ..color = TrovoColors.found.withValues(alpha: 0.16 * highlight)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + 10 * highlight),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(innerRect.deflate(3), const Radius.circular(10)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = TrovoColors.found.withValues(alpha: highlight),
      );
    }

    // Piano di appoggio visto un po' dall'alto (effetto 2.5D).
    final surfaceH = size.height * 0.05;
    final surface = Path()
      ..moveTo(uw + 6, boardY - surfaceH)
      ..lineTo(size.width - uw - 6, boardY - surfaceH)
      ..lineTo(size.width - uw + 4, boardY)
      ..lineTo(uw - 4, boardY)
      ..close();
    canvas.drawPath(surface, Paint()..color = const Color(0xFF454C59));

    // Bordo frontale del ripiano, nel colore del piano.
    final lipH = size.height * 0.14;
    final lip = Rect.fromLTWH(uw - 6, boardY, size.width - 2 * uw + 12, lipH);
    final lipColor = Color.lerp(color, TrovoColors.found, highlight)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(lip, const Radius.circular(5)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lipColor, Color.lerp(lipColor, Colors.black, 0.22)!],
        ).createShader(lip),
    );
    // Ombra sotto il ripiano.
    canvas.drawRect(
      Rect.fromLTWH(uw, boardY + lipH, size.width - 2 * uw, size.height * 0.06),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, boardY + lipH, 1, size.height * 0.06)),
    );

    paintUpright(canvas, Rect.fromLTWH(0, 0, uw, size.height), holeOffset: yOffset);
    paintUpright(canvas, Rect.fromLTWH(size.width - uw, 0, uw, size.height),
        holeOffset: yOffset);
  }

  @override
  bool shouldRepaint(LevelFramePainter old) =>
      old.color != color ||
      old.highlight != highlight ||
      old.pressed != pressed ||
      old.yOffset != yOffset;
}

/// Parte alta dello scaffale (tappi dei montanti).
class ShelfCapPainter extends CustomPainter {
  ShelfCapPainter({this.uprightWidth = LevelFramePainter.uprightWidth});
  final double uprightWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final uw = uprightWidth;
    for (final x in [0.0, size.width - uw]) {
      paintUpright(canvas, Rect.fromLTWH(x, 6, uw, size.height - 6));
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x - 2, 0, uw + 4, 9), const Radius.circular(3)),
        Paint()..color = TrovoColors.metalDark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Parte bassa dello scaffale (piedini).
class ShelfFeetPainter extends CustomPainter {
  ShelfFeetPainter({required this.yOffset, this.uprightWidth = LevelFramePainter.uprightWidth});
  final double yOffset;
  final double uprightWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final uw = uprightWidth;
    for (final x in [0.0, size.width - uw]) {
      paintUpright(canvas, Rect.fromLTWH(x, 0, uw, size.height - 6), holeOffset: yOffset);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 4, size.height - 8, uw + 8, 8), const Radius.circular(3)),
        Paint()..color = TrovoColors.metalDark,
      );
    }
    // Ombra sul pavimento.
    canvas.drawOval(
      Rect.fromLTWH(-10, size.height - 6, size.width + 20, 12),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(ShelfFeetPainter old) => old.yOffset != yOffset;
}

/// Widget comodo per lo scaffale in miniatura, con bagliore animabile.
class MiniShelf extends StatelessWidget {
  const MiniShelf({
    super.key,
    required this.levelColors,
    required this.slots,
    this.highlightIndex,
    this.highlightPositions = const {},
    this.glow = 0,
    this.width = 120,
    this.height = 140,
  });

  final List<Color> levelColors;
  final List<List<bool>> slots;
  final int? highlightIndex;
  final Set<int> highlightPositions;
  final double glow;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: MiniShelfPainter(
          levelColors: levelColors,
          slots: slots,
          highlightIndex: highlightIndex,
          highlightPositions: highlightPositions,
          glow: glow,
        ),
      ),
    );
  }
}
