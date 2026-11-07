import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'shelf_art.dart';

/// Uno scomparto da disegnare in miniatura.
class MiniCompartment {
  const MiniCompartment(this.kind, this.color, this.slots);
  final LevelKind kind;
  final Color color;

  /// true = posto occupato.
  final List<bool> slots;
}

List<MiniCompartment> miniCompartments(Shelf shelf) => [
      for (final l in shelf.levels)
        MiniCompartment(l.kind, TrovoColors.level(l.colorIndex), [for (final s in l.slots) s != null]),
    ];

/// Mobile in miniatura, visto di fronte: scaffale, cassettiera, armadio, cubi, mobile chiuso.
class MiniFurniture extends StatelessWidget {
  const MiniFurniture({
    super.key,
    required this.kind,
    required this.compartments,
    this.gridColumns = 1,
    this.bodyColor,
    this.highlightIndex,
    this.highlightPositions = const {},
    this.glow = 0,
    this.width = 120,
    this.height = 140,
  });

  final FurnitureKind kind;
  final List<MiniCompartment> compartments;
  final int gridColumns;
  final Color? bodyColor;
  final int? highlightIndex;
  final Set<int> highlightPositions;
  final double glow;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (kind == FurnitureKind.shelf) {
      return MiniShelf(
        width: width,
        height: height,
        levelColors: [for (final c in compartments) c.color],
        slots: [for (final c in compartments) c.slots],
        highlightIndex: highlightIndex,
        highlightPositions: highlightPositions,
        glow: glow,
      );
    }
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _MiniFurniturePainter(
          kind: kind,
          compartments: compartments,
          gridColumns: gridColumns,
          bodyColor: bodyColor ?? TrovoColors.metal,
          highlightIndex: highlightIndex,
          glow: glow,
        ),
      ),
    );
  }
}

class _MiniFurniturePainter extends CustomPainter {
  _MiniFurniturePainter({
    required this.kind,
    required this.compartments,
    required this.gridColumns,
    required this.bodyColor,
    this.highlightIndex,
    this.glow = 0,
  });

  final FurnitureKind kind;
  final List<MiniCompartment> compartments;
  final int gridColumns;
  final Color bodyColor;
  final int? highlightIndex;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Rect.fromLTWH(2, 2, size.width - 4, size.height - 8);
    final side = math.max(3.0, size.width * 0.05);
    final radius = math.min(8.0, size.width * 0.06);

    // Ombra sul pavimento e piedini.
    canvas.drawOval(
      Rect.fromLTWH(-2, size.height - 9, size.width + 4, 10),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    final feet = Paint()..color = TrovoColors.metalDark;
    canvas.drawRect(Rect.fromLTWH(body.left + side, body.bottom, side, 5), feet);
    canvas.drawRect(Rect.fromLTWH(body.right - 2 * side, body.bottom, side, 5), feet);

    // Corpo del mobile.
    final bodyRR = RRect.fromRectAndRadius(body, Radius.circular(radius));
    canvas.drawRRect(
      bodyRR,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(TrovoColors.surfaceHigher, bodyColor, 0.30)!,
            Color.lerp(TrovoColors.surface, bodyColor, 0.18)!,
          ],
        ).createShader(body),
    );
    canvas.drawRRect(
      bodyRR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Color.lerp(TrovoColors.metalDark, bodyColor, 0.4)!,
    );

    final inner = body.deflate(side);
    if (compartments.isEmpty) return;

    if (kind == FurnitureKind.cubes) {
      final cols = math.max(1, gridColumns);
      final rows = (compartments.length / cols).ceil();
      final cw = inner.width / cols;
      final ch = inner.height / rows;
      for (var i = 0; i < compartments.length; i++) {
        final r = i ~/ cols;
        final c = i % cols;
        final cell = Rect.fromLTWH(inner.left + c * cw, inner.top + r * ch, cw, ch).deflate(math.max(1.5, cw * 0.06));
        _cube(canvas, cell, compartments[i], i == highlightIndex);
      }
      return;
    }

    // Altezze: l'asta (grucce) è più alta, i cassetti più bassi.
    double weight(LevelKind k) => switch (k) {
          LevelKind.rail => 2.6,
          LevelKind.drawer => 0.8,
          LevelKind.board => 1.0,
          LevelKind.cube => 1.0,
        };
    final total = compartments.fold<double>(0, (s, c) => s + weight(c.kind));
    var y = inner.top;
    for (var i = 0; i < compartments.length; i++) {
      final c = compartments[i];
      final h = inner.height * weight(c.kind) / total;
      final rect = Rect.fromLTWH(inner.left, y, inner.width, h);
      final hi = i == highlightIndex;
      switch (c.kind) {
        case LevelKind.drawer:
          _drawer(canvas, rect.deflate(math.max(1.2, h * 0.06)), c, hi);
        case LevelKind.rail:
          _rail(canvas, rect, c, hi);
        case LevelKind.board:
        case LevelKind.cube:
          _board(canvas, rect, c, hi);
      }
      y += h;
    }
  }

  Color _hiColor(Color c, bool hi) => hi ? Color.lerp(c, TrovoColors.found, glow)! : c;

  void _drawer(Canvas canvas, Rect r, MiniCompartment c, bool hi) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(math.min(4, r.height * 0.2)));
    canvas.drawRRect(rr, Paint()..color = Color.lerp(TrovoColors.surfaceHigh, c.color, hi ? 0.35 * glow + 0.12 : 0.12)!);
    // Filo colorato in alto.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top, r.width, math.max(1.5, r.height * 0.12)), const Radius.circular(2)),
      Paint()..color = _hiColor(c.color, hi),
    );
    // Maniglia.
    final hw = r.width * 0.3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: r.center.translate(0, r.height * 0.06), width: hw, height: math.max(1.5, r.height * 0.12)),
        const Radius.circular(2),
      ),
      Paint()..color = TrovoColors.metalLight,
    );
    if (hi && glow > 0) {
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = TrovoColors.found.withValues(alpha: glow),
      );
    }
  }

  void _board(Canvas canvas, Rect r, MiniCompartment c, bool hi) {
    // Vano aperto: fondo più scuro, oggetti, ripiano colorato.
    canvas.drawRect(r, Paint()..color = Colors.black.withValues(alpha: 0.22));
    final boardH = math.max(1.5, r.height * 0.1);
    final boardY = r.bottom - boardH;
    final n = c.slots.length;
    if (n > 0) {
      final cw = r.width / n;
      final bw = cw * 0.7;
      for (var p = 0; p < n; p++) {
        if (!c.slots[p]) continue;
        final bh = (r.height - boardH) * (0.45 + 0.25 * ((p * 7) % 3) / 2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(r.left + p * cw + (cw - bw) / 2, boardY - bh, bw, bh), const Radius.circular(2)),
          Paint()..color = _hiColor(c.color, hi).withValues(alpha: hi ? 0.5 + 0.4 * glow : 0.6),
        );
      }
    }
    canvas.drawRect(Rect.fromLTWH(r.left, boardY, r.width, boardH), Paint()..color = _hiColor(c.color, hi));
  }

  void _rail(Canvas canvas, Rect r, MiniCompartment c, bool hi) {
    canvas.drawRect(r, Paint()..color = Colors.black.withValues(alpha: 0.22));
    final rodY = r.top + math.max(3, r.height * 0.1);
    canvas.drawLine(
      Offset(r.left + 1, rodY),
      Offset(r.right - 1, rodY),
      Paint()
        ..color = TrovoColors.metalLight
        ..strokeWidth = math.max(1.5, r.height * 0.03),
    );
    final n = c.slots.length;
    if (n == 0) return;
    final cw = r.width / n;
    for (var p = 0; p < n; p++) {
      final cx = r.left + p * cw + cw / 2;
      final hook = Paint()
        ..color = TrovoColors.metalLight.withValues(alpha: 0.8)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      final hy = rodY + math.max(3, r.height * 0.08);
      canvas.drawLine(Offset(cx, rodY), Offset(cx, hy), hook);
      canvas.drawLine(Offset(cx - cw * 0.35, hy + 2), Offset(cx, hy), hook);
      canvas.drawLine(Offset(cx + cw * 0.35, hy + 2), Offset(cx, hy), hook);
      if (c.slots[p]) {
        final cloth = Rect.fromLTWH(cx - cw * 0.36, hy + 2, cw * 0.72, (r.bottom - hy - 4) * (0.6 + 0.3 * (p % 2)));
        canvas.drawRRect(
          RRect.fromRectAndRadius(cloth, const Radius.circular(2)),
          Paint()..color = _hiColor(c.color, hi).withValues(alpha: 0.65),
        );
      }
    }
  }

  void _cube(Canvas canvas, Rect r, MiniCompartment c, bool hi) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(math.min(3, r.width * 0.08)));
    canvas.drawRRect(rr, Paint()..color = Colors.black.withValues(alpha: 0.28));
    final used = c.slots.where((s) => s).length;
    if (used > 0) {
      final box = Rect.fromLTWH(r.left + r.width * 0.12, r.top + r.height * 0.3, r.width * 0.76, r.height * 0.62);
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(2)),
        Paint()..color = _hiColor(c.color, hi).withValues(alpha: hi ? 0.5 + 0.4 * glow : 0.55),
      );
    }
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hi && glow > 0 ? 2 : 1
        ..color = hi && glow > 0 ? TrovoColors.found.withValues(alpha: glow) : c.color.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_MiniFurniturePainter old) => true;
}

/// Fianco di un mobile chiuso (laminato), al posto del montante in ferro.
void paintPanelSide(Canvas canvas, Rect rect, Color tint, {required bool left}) {
  final rr = RRect.fromRectAndRadius(rect, const Radius.circular(3));
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = LinearGradient(
        begin: left ? Alignment.centerLeft : Alignment.centerRight,
        end: left ? Alignment.centerRight : Alignment.centerLeft,
        colors: [
          Color.lerp(TrovoColors.surfaceHigher, tint, 0.45)!,
          Color.lerp(TrovoColors.surface, tint, 0.25)!,
        ],
      ).createShader(rect),
  );
  canvas.drawLine(
    Offset(left ? rect.right - 0.5 : rect.left + 0.5, rect.top),
    Offset(left ? rect.right - 0.5 : rect.left + 0.5, rect.bottom),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = 1,
  );
}

/// Top del mobile chiuso.
class PanelCapPainter extends CustomPainter {
  PanelCapPainter(this.tint);
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(-4, 0, size.width + 8, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(5)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(TrovoColors.surfaceHigher, tint, 0.55)!, Color.lerp(TrovoColors.surface, tint, 0.3)!],
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(PanelCapPainter old) => old.tint != tint;
}

/// Zoccolo e ombra del mobile chiuso.
class PanelFeetPainter extends CustomPainter {
  PanelFeetPainter(this.tint);
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromLTWH(-10, size.height - 6, size.width + 20, 12),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    final r = Rect.fromLTWH(0, 0, size.width, size.height - 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(4)),
      Paint()..color = Color.lerp(TrovoColors.surface, tint, 0.2)!,
    );
  }

  @override
  bool shouldRepaint(PanelFeetPainter old) => old.tint != tint;
}
