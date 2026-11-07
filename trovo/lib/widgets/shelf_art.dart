import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Disegno dei mobili in stile "vetro": alluminio satinato, ripiani in vetro fumé,
/// bordo frontale luminoso nel colore del piano. Luce unica da in alto a sinistra.

const _slotSpacing = 14.0;

/// Montante in alluminio satinato, con microfessure.
void paintUpright(Canvas canvas, Rect rect, {double holeOffset = 0}) {
  final r = RRect.fromRectAndRadius(rect, Radius.circular(math.min(3, rect.width / 2)));
  canvas.drawRRect(
    r,
    Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2B2F37), Color(0xFF6A707C), Color(0xFF24272E)],
        stops: [0, 0.3, 1],
      ).createShader(rect),
  );
  final slot = Paint()..color = Colors.black.withValues(alpha: 0.25);
  final w = math.max(1.5, rect.width * 0.25);
  final h = math.max(3.0, rect.width * 0.62);
  final start = rect.top + ((_slotSpacing - holeOffset % _slotSpacing) % _slotSpacing) + 4;
  for (var y = start; y < rect.bottom - h - 1; y += _slotSpacing) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(rect.center.dx - w / 2, y, w, h), Radius.circular(w / 2)),
      slot,
    );
  }
}

/// Ripiano in vetro fumé con bordo frontale nel colore del piano e striscia "LED" sotto.
void paintGlassBoard(
  Canvas canvas, {
  required double left,
  required double right,
  required double backY,
  required double frontY,
  required double edgeH,
  required Color color,
  double glow = 0,
  double ledH = 0,
  double inset = 8,
}) {
  final face = Path()
    ..moveTo(left + inset, backY)
    ..lineTo(right - inset, backY)
    ..lineTo(right, frontY)
    ..lineTo(left, frontY)
    ..close();
  canvas.drawPath(
    face,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withValues(alpha: 0.02), Colors.white.withValues(alpha: 0.08)],
      ).createShader(Rect.fromLTRB(left, backY, right, frontY)),
  );
  final c = Color.lerp(color, TrovoColors.found, glow)!;
  final edge = Rect.fromLTRB(left, frontY, right, frontY + edgeH);
  canvas.drawRRect(
    RRect.fromRectAndRadius(edge, Radius.circular(edgeH / 2)),
    Paint()
      ..shader = LinearGradient(
        colors: [c.withValues(alpha: 0.95), c.withValues(alpha: 0.55)],
      ).createShader(edge),
  );
  // Filo di luce sul bordo.
  canvas.drawLine(
    Offset(left + 2, frontY + 0.5),
    Offset(right - 2, frontY + 0.5),
    Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1,
  );
  // Bagliore del bordo.
  canvas.drawRRect(
    RRect.fromRectAndRadius(edge.inflate(1), Radius.circular(edgeH)),
    Paint()
      ..color = c.withValues(alpha: 0.35 + 0.3 * glow)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + 8 * glow),
  );
  if (ledH > 0) {
    final led = Rect.fromLTRB(left + 4, frontY + edgeH, right - 4, frontY + edgeH + ledH);
    canvas.drawRect(
      led,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.10), Colors.white.withValues(alpha: 0)],
        ).createShader(led),
    );
  }
}

/// Scaffale in miniatura (Home, risultati di ricerca).
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
    final uw = (size.width * 0.05).clamp(3.0, 7.0);
    const top = 3.0;
    final feet = (size.height * 0.04).clamp(3.0, 8.0);
    final levelH = (size.height - top - feet) / n;
    final edgeH = (levelH * 0.09).clamp(1.5, 4.0);
    final innerLeft = uw + 1;
    final innerRight = size.width - uw - 1;
    final innerW = innerRight - innerLeft;

    // Luce dall'alto.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -1.1),
          radius: 1.2,
          colors: [Colors.white.withValues(alpha: 0.07), Colors.white.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );

    for (var i = 0; i < levelColors.length; i++) {
      final cellTop = top + i * levelH;
      final frontY = cellTop + levelH - edgeH;
      final color = levelColors[i];
      final isHi = highlightIndex == i;
      final dim = highlightIndex != null && !isHi && glow > 0 ? 0.4 : 1.0;

      final row = slots.length > i ? slots[i] : const <bool>[];
      if (row.isNotEmpty) {
        final colW = innerW / row.length;
        final blockW = colW * 0.7;
        for (var p = 0; p < row.length; p++) {
          if (!row[p]) continue;
          final h = (levelH - edgeH) * _blockHeights[(p + i) % _blockHeights.length] * 0.85;
          final x = innerLeft + p * colW + (colW - blockW) / 2;
          final rect = Rect.fromLTWH(x, frontY - h - 1, blockW, h);
          final hiBlock = isHi && (highlightPositions.isEmpty || highlightPositions.contains(p));
          final c = hiBlock ? Color.lerp(color, TrovoColors.found, glow)! : color;
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(math.min(blockW * 0.25, 3))),
            Paint()..color = c.withValues(alpha: (hiBlock ? 0.45 + 0.45 * glow : 0.38) * dim),
          );
          if (hiBlock && glow > 0) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect.inflate(1.5), const Radius.circular(3)),
              Paint()
                ..color = TrovoColors.found.withValues(alpha: 0.5 * glow)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
            );
          }
        }
      }

      final edge = Rect.fromLTWH(innerLeft - 1, frontY, innerW + 2, edgeH);
      final ec = isHi ? Color.lerp(color, TrovoColors.found, glow)! : color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(edge, Radius.circular(edgeH / 2)),
        Paint()..color = ec.withValues(alpha: 0.85 * dim),
      );
    }

    paintUpright(canvas, Rect.fromLTWH(0, 0, uw, size.height));
    paintUpright(canvas, Rect.fromLTWH(size.width - uw, 0, uw, size.height));
  }

  @override
  bool shouldRepaint(MiniShelfPainter old) =>
      old.glow != glow ||
      old.highlightIndex != highlightIndex ||
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

/// Un piano semplice (usato nell'anteprima di "Nuovo scaffale").
class LevelFramePainter extends CustomPainter {
  LevelFramePainter({required this.color, required this.yOffset, this.highlight = 0, this.pressed = 0});

  final Color color;
  final double yOffset;
  final double highlight;
  final double pressed;

  static const uprightWidth = 8.0;
  static const boardTop = 0.8;

  @override
  void paint(Canvas canvas, Size size) {
    const uw = uprightWidth;
    final frontY = size.height * boardTop;
    paintGlassBoard(
      canvas,
      left: uw,
      right: size.width - uw,
      backY: frontY - size.height * 0.12,
      frontY: frontY,
      edgeH: math.max(3, size.height * 0.09),
      color: color,
      glow: highlight,
      inset: 4,
    );
    paintUpright(canvas, Rect.fromLTWH(0, 0, uw, size.height), holeOffset: yOffset);
    paintUpright(canvas, Rect.fromLTWH(size.width - uw, 0, uw, size.height), holeOffset: yOffset);
  }

  @override
  bool shouldRepaint(LevelFramePainter old) =>
      old.color != color || old.highlight != highlight || old.pressed != pressed || old.yOffset != yOffset;
}

/// Parte alta dello scaffale (tappi dei montanti).
class ShelfCapPainter extends CustomPainter {
  ShelfCapPainter({this.uprightWidth = LevelFramePainter.uprightWidth});
  final double uprightWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final uw = uprightWidth;
    for (final x in [0.0, size.width - uw]) {
      paintUpright(canvas, Rect.fromLTWH(x, 4, uw, size.height - 4));
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x - 1, 0, uw + 2, 6), const Radius.circular(3)),
        Paint()..color = const Color(0xFF3A3F49),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ShelfCapPainter oldDelegate) => oldDelegate.uprightWidth != uprightWidth;
}

/// Parte bassa dello scaffale (piedini e ombra sul pavimento).
class ShelfFeetPainter extends CustomPainter {
  ShelfFeetPainter({required this.yOffset, this.uprightWidth = LevelFramePainter.uprightWidth});
  final double yOffset;
  final double uprightWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final uw = uprightWidth;
    canvas.drawOval(
      Rect.fromLTWH(-6, size.height - 10, size.width + 12, 14),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    for (final x in [0.0, size.width - uw]) {
      paintUpright(canvas, Rect.fromLTWH(x, 0, uw, size.height - 6), holeOffset: yOffset);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x - 2, size.height - 7, uw + 4, 6), const Radius.circular(3)),
        Paint()..color = const Color(0xFF3A3F49),
      );
    }
  }

  @override
  bool shouldRepaint(ShelfFeetPainter old) => old.yOffset != yOffset || old.uprightWidth != uprightWidth;
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
