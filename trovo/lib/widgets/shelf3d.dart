import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store_scope.dart';
import '../theme.dart';
import 'common.dart';
import 'shelf_art.dart' show paintUpright;

/// Quello che si trascina: un oggetto con tutti i suoi posti.
class DragPayload {
  const DragPayload({required this.item, required this.level, required this.grab, required this.span});
  final Item item;
  final Level level;

  /// Quale dei suoi posti hai preso col dito (0 = il primo a sinistra).
  final int grab;
  final int span;
}

/// Dove finirebbe l'oggetto trascinato (per l'effetto "calamita").
class DropHover {
  const DropHover({required this.levelId, required this.start, required this.span, required this.ok});
  final String levelId;
  final int start;
  final int span;
  final bool ok;

  bool covers(String level, int pos) => level == levelId && pos >= start && pos < start + span;

  @override
  bool operator ==(Object other) =>
      other is DropHover && other.levelId == levelId && other.start == start && other.span == span && other.ok == ok;

  @override
  int get hashCode => Object.hash(levelId, start, span, ok);
}

/// Misure di un piano, calcolate dalla larghezza: più posti = oggetti più piccoli.
class LevelGeometry {
  LevelGeometry(double width, int slotCount) {
    frameW = width - tagW - addW;
    colsW = frameW - 2 * uprightW - 2 * pad;
    final natural = colsW / math.max(1, slotCount);
    colW = math.max(natural, minColW);
    contentW = colW * slotCount;
    scrolls = contentW > colsW + 0.5;
    unit = (colW * 0.8).clamp(16.0, 52.0);
    step = unit * 0.25;
    floorDepth = unit * 0.3 + 6;
    height = math.max(118.0, top + unit + (maxVisible - 1) * step + floorDepth + lipH + 6);
    floorFrontY = height - lipH;
    floorBackY = floorFrontY - floorDepth;
  }

  static const tagW = 42.0;
  static const addW = 40.0;
  static const uprightW = 14.0;
  static const pad = 6.0;
  static const minColW = 26.0;
  static const lipH = 20.0;
  static const top = 8.0;

  /// Quante unità si vedono in fila, una dietro l'altra.
  static const maxVisible = 6;

  late final double frameW;
  late final double colsW;
  late final double colW;
  late final double contentW;
  late final bool scrolls;
  late final double unit;
  late final double step;
  late final double floorDepth;
  late final double height;
  late final double floorFrontY;
  late final double floorBackY;
}

/// Quante unità vanno in ciascuna fila: 12 pomarole su 2 posti = 6 + 6.
List<int> splitQuantity(int quantity, int span) {
  final base = quantity ~/ span;
  final rest = quantity % span;
  return [for (var c = 0; c < span; c++) base + (c < rest ? 1 : 0)];
}

/// Un piano dello scaffale visto in 3D: posti da sinistra a destra,
/// e in ogni posto le cose in fila, una dietro l'altra.
class Level3DRow extends StatelessWidget {
  const Level3DRow({
    super.key,
    required this.shelf,
    required this.level,
    required this.number,
    required this.yOffset,
    required this.onTapEmpty,
    required this.onLongPressEmpty,
    required this.onTapItem,
    required this.onAddSlot,
    required this.onOpenLevel,
    required this.onHover,
    required this.onHoverEnd,
    required this.onDrop,
    this.glow = 0,
    this.glowPositions = const {},
    this.pulseItemId,
    this.hover,
  });

  final Shelf shelf;
  final Level level;
  final int number;
  final double yOffset;
  final double glow;
  final Set<int> glowPositions;
  final String? pulseItemId;
  final DropHover? hover;

  final void Function(int pos) onTapEmpty;
  final void Function(int pos) onLongPressEmpty;
  final void Function(Item item) onTapItem;
  final VoidCallback onAddSlot;
  final VoidCallback onOpenLevel;
  final void Function(DragPayload payload, int pos) onHover;
  final VoidCallback onHoverEnd;
  final bool Function(DragPayload payload, int pos) onDrop;

  @override
  Widget build(BuildContext context) {
    final color = TrovoColors.level(level.colorIndex);
    final s = context.s;
    return LayoutBuilder(builder: (context, c) {
      final g = LevelGeometry(c.maxWidth, level.slotCount);
      final columns = _Columns(row: this, g: g, color: color);
      return SizedBox(
        height: g.height,
        child: Row(
          children: [
            // Etichetta del piano: toccala per aprire la lista.
            SizedBox(
              width: LevelGeometry.tagW,
              child: Align(
                alignment: Alignment(0, (g.floorFrontY + 10) / g.height * 2 - 1),
                child: Semantics(
                  button: true,
                  label: '${s.level(number)}, ${s.itemsCount(level.items.length)}',
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onOpenLevel();
                    },
                    child: LevelTag(number: number, color: color, size: 32, glow: glow),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: g.frameW,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FramePainter(g: g, color: color, yOffset: yOffset, glow: glow),
                    ),
                  ),
                  Positioned(
                    left: LevelGeometry.uprightW + LevelGeometry.pad,
                    right: LevelGeometry.uprightW + LevelGeometry.pad,
                    top: 0,
                    bottom: 0,
                    child: g.scrolls
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(width: g.contentW, child: columns),
                          )
                        : columns,
                  ),
                ],
              ),
            ),
            // + : aggiunge un posto in fondo al piano.
            SizedBox(
              width: LevelGeometry.addW,
              child: Center(
                child: Tooltip(
                  message: s.addSlot,
                  child: Material(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onAddSlot();
                      },
                      child: SizedBox(
                        width: 34,
                        height: math.min(64, g.height - 30),
                        child: Icon(Icons.add_rounded, color: color, size: 26),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _Columns extends StatelessWidget {
  const _Columns({required this.row, required this.g, required this.color});
  final Level3DRow row;
  final LevelGeometry g;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final level = row.level;
    final children = <Widget>[];
    final duration = Motion.of(context, 280);

    // Linee del pavimento: si vede dove finisce un posto e inizia l'altro.
    children.add(Positioned.fill(
      child: CustomPaint(
        painter: _FloorGridPainter(
          g: g,
          count: level.slotCount,
          glowPositions: row.glowPositions,
          glow: row.glow,
          hover: row.hover?.levelId == level.id ? row.hover : null,
        ),
      ),
    ));

    // Numeri dei posti sul bordo: uguali a quelli delle etichette QR.
    for (var pos = 0; pos < level.slotCount; pos++) {
      children.add(Positioned(
        left: pos * g.colW,
        width: g.colW,
        top: g.floorFrontY + 2,
        height: LevelGeometry.lipH - 4,
        child: IgnorePointer(
          child: Center(
            child: Text(
              '${pos + 1}',
              style: TextStyle(
                fontFamily: TrovoTheme.fontFamily,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                height: 1,
                color: TrovoColors.onColor(color).withValues(alpha: 0.75),
              ),
            ),
          ),
        ),
      ));
    }

    for (final block in level.blocks) {
      final left = block.start * g.colW;
      final width = block.span * g.colW;
      if (block.isEmpty) {
        children.add(AnimatedPositioned(
          key: ValueKey('empty-${block.start}'),
          duration: duration,
          curve: Curves.easeOutCubic,
          left: left,
          width: width,
          top: 0,
          height: g.floorFrontY,
          child: _EmptySlot(
            g: g,
            glow: row.glowPositions.contains(block.start) ? row.glow : 0,
            onTap: () => row.onTapEmpty(block.start),
            onLongPress: () => row.onLongPressEmpty(block.start),
          ),
        ));
      } else {
        final item = block.item!;
        final glowing = row.glowPositions.contains(block.start) ? row.glow : 0.0;
        final visual = _BlockVisual(
          item: item,
          span: block.span,
          g: g,
          glow: glowing,
          pulse: item.id == row.pulseItemId ? row.glow : 0,
        );
        children.add(AnimatedPositioned(
          key: ValueKey('item-${item.id}'),
          duration: duration,
          curve: Curves.easeOutCubic,
          left: left,
          width: width,
          top: 0,
          height: g.floorFrontY,
          child: _DraggableBlock(
            item: item,
            level: level,
            span: block.span,
            g: g,
            visual: visual,
            onTap: () => row.onTapItem(item),
          ),
        ));
      }
    }

    // Bersagli per il trascinamento, sopra a tutto ma "trasparenti" ai tocchi.
    for (var pos = 0; pos < level.slotCount; pos++) {
      children.add(Positioned(
        left: pos * g.colW,
        width: g.colW,
        top: 0,
        bottom: 0,
        child: DragTarget<DragPayload>(
          onWillAcceptWithDetails: (d) {
            row.onHover(d.data, pos);
            return true;
          },
          onMove: (d) => row.onHover(d.data, pos),
          onLeave: (_) => row.onHoverEnd(),
          onAcceptWithDetails: (d) => row.onDrop(d.data, pos),
          builder: (_, _, _) => const SizedBox.expand(),
        ),
      ));
    }

    return Stack(clipBehavior: Clip.none, children: children);
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.g, required this.glow, required this.onTap, required this.onLongPress});
  final LevelGeometry g;
  final double glow;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final size = g.unit * 0.92;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
      child: Semantics(
        button: true,
        label: context.s.emptySlot,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: 3),
            child: CustomPaint(
              painter: _DashedBoxPainter(
                color: Color.lerp(TrovoColors.metalDark, TrovoColors.found, glow)!,
                radius: size * 0.24,
              ),
              child: SizedBox(
                width: size,
                height: size,
                child: Icon(
                  Icons.add_rounded,
                  size: size * 0.5,
                  color: Color.lerp(TrovoColors.metal, TrovoColors.found, glow),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DraggableBlock extends StatefulWidget {
  const _DraggableBlock({
    required this.item,
    required this.level,
    required this.span,
    required this.g,
    required this.visual,
    required this.onTap,
  });

  final Item item;
  final Level level;
  final int span;
  final LevelGeometry g;
  final Widget visual;
  final VoidCallback onTap;

  @override
  State<_DraggableBlock> createState() => _DraggableBlockState();
}

class _DraggableBlockState extends State<_DraggableBlock> {
  int _grab = 0;

  @override
  Widget build(BuildContext context) {
    final g = widget.g;
    return Listener(
      // Ricorda quale posto del blocco hai preso col dito.
      onPointerDown: (e) => _grab = (e.localPosition.dx / g.colW).floor().clamp(0, widget.span - 1),
      child: LongPressDraggable<DragPayload>(
        data: DragPayload(item: widget.item, level: widget.level, grab: _grab, span: widget.span),
        hapticFeedbackOnStart: true,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Transform.translate(
          offset: Offset(-(_grab + 0.5) * g.colW, -g.floorFrontY * 0.75),
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              width: widget.span * g.colW,
              height: g.floorFrontY,
              child: Transform.scale(scale: 1.08, child: Opacity(opacity: 0.92, child: widget.visual)),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.25, child: widget.visual),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: Semantics(
            button: true,
            label: '${widget.item.name}, ${widget.item.quantity}',
            child: widget.visual,
          ),
        ),
      ),
    );
  }
}

/// Le unità di un oggetto in fila, dalla più lontana alla più vicina.
class _BlockVisual extends StatelessWidget {
  const _BlockVisual({required this.item, required this.span, required this.g, required this.glow, required this.pulse});

  final Item item;
  final int span;
  final LevelGeometry g;
  final double glow;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final perColumn = splitQuantity(item.quantity, span);
    final width = span * g.colW;
    final showName = width >= 38;
    // Il nome sta subito sopra la fila più alta.
    final tallest = math.min(perColumn.reduce(math.max), LevelGeometry.maxVisible);
    final stackTop = 3 + (tallest - 1) * g.step + g.unit * (1 - 0.075 * (tallest - 1));
    final nameBottom = math.min(stackTop + 3, g.floorFrontY - 18);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var c = 0; c < span; c++)
          Positioned(
            left: c * g.colW,
            width: g.colW,
            top: 0,
            bottom: 0,
            child: _Column(item: item, count: perColumn[c], g: g, glow: glow, pulse: c == 0 ? pulse : 0),
          ),
        if (showName)
          Positioned(
            left: 1,
            right: 1,
            bottom: nameBottom,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: TrovoColors.background.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: TrovoTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: width >= 70 ? 13 : 11,
                    color: TrovoColors.text,
                  ),
                ),
              ),
            ),
          ),
        if (item.quantity > 1)
          Positioned(
            right: 0,
            bottom: g.unit * 0.85,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: TrovoColors.primary,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: TrovoColors.background, width: 1.5),
              ),
              child: Text(
                '${item.quantity}',
                style: const TextStyle(
                  fontFamily: TrovoTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: TrovoColors.onPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.item, required this.count, required this.g, required this.glow, required this.pulse});

  final Item item;
  final int count;
  final LevelGeometry g;
  final double glow;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final visible = math.min(count, LevelGeometry.maxVisible);
    final extra = count - visible;
    final units = <Widget>[];
    // Disegna dal fondo verso davanti, così quella davanti copre le altre.
    for (var j = visible - 1; j >= 0; j--) {
      final scale = 1 - 0.075 * j;
      final size = g.unit * scale;
      final darken = 0.13 * j;
      units.add(Positioned(
        bottom: 3 + j * g.step,
        left: (g.colW - size) / 2,
        child: Transform.scale(
          scale: j == 0 ? 1 + 0.16 * pulse : 1,
          child: _Unit(item: item, size: size, darken: darken, glow: j == 0 ? glow : glow * 0.5),
        ),
      ));
    }
    if (extra > 0) {
      units.add(Positioned(
        bottom: 3 + visible * g.step + g.unit * 0.55,
        left: 0,
        right: 0,
        child: Center(
          child: Text(
            '+$extra',
            style: const TextStyle(
              fontFamily: TrovoTheme.fontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: TrovoColors.textMuted,
            ),
          ),
        ),
      ));
    }
    return Stack(clipBehavior: Clip.none, children: units);
  }
}

/// Una singola confezione: adesivo con l'emoji.
class _Unit extends StatelessWidget {
  const _Unit({required this.item, required this.size, required this.darken, required this.glow});
  final Item item;
  final double size;
  final double darken;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      foregroundDecoration: darken > 0
          ? BoxDecoration(
              color: Colors.black.withValues(alpha: darken),
              borderRadius: BorderRadius.circular(size * 0.26),
            )
          : null,
      decoration: BoxDecoration(
        color: TrovoColors.surfaceHigher,
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(
          color: Color.lerp(Colors.white.withValues(alpha: 0.85), TrovoColors.found, glow)!,
          width: size > 30 ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2)),
          if (glow > 0) BoxShadow(color: TrovoColors.found.withValues(alpha: 0.7 * glow), blurRadius: 16 * glow),
        ],
      ),
      child: Text(item.emoji, style: TextStyle(fontSize: size * 0.55, height: 1.1)),
    );
  }
}

/// Cornice del piano: fondo, pavimento in prospettiva, bordo colorato, montanti.
class _FramePainter extends CustomPainter {
  _FramePainter({required this.g, required this.color, required this.yOffset, required this.glow});
  final LevelGeometry g;
  final Color color;
  final double yOffset;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    const uw = LevelGeometry.uprightW;
    final inner = Rect.fromLTRB(uw, 0, size.width - uw, g.floorBackY);

    // Parete di fondo.
    canvas.drawRect(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(TrovoColors.background, color, 0.03)!,
            Color.lerp(const Color(0xFF1A1D23), color, 0.08)!,
          ],
        ).createShader(inner),
    );

    // Pavimento visto un po' dall'alto: più stretto dietro, più largo davanti.
    const inset = 10.0;
    final floor = Path()
      ..moveTo(uw + inset, g.floorBackY)
      ..lineTo(size.width - uw - inset, g.floorBackY)
      ..lineTo(size.width - uw + 2, g.floorFrontY)
      ..lineTo(uw - 2, g.floorFrontY)
      ..close();
    canvas.drawPath(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E333D), Color(0xFF4A5160)],
        ).createShader(Rect.fromLTRB(0, g.floorBackY, size.width, g.floorFrontY)),
    );

    if (glow > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(uw + 2, 2, size.width - uw - 2, g.floorFrontY), const Radius.circular(10)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = TrovoColors.found.withValues(alpha: 0.55 * glow),
      );
    }

    // Bordo frontale nel colore del piano.
    final lip = Rect.fromLTWH(uw - 6, g.floorFrontY, size.width - 2 * uw + 12, LevelGeometry.lipH);
    final lipColor = Color.lerp(color, TrovoColors.found, glow * 0.6)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(lip, const Radius.circular(5)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lipColor, Color.lerp(lipColor, Colors.black, 0.22)!],
        ).createShader(lip),
    );

    paintUpright(canvas, Rect.fromLTWH(0, 0, uw, size.height), holeOffset: yOffset);
    paintUpright(canvas, Rect.fromLTWH(size.width - uw, 0, uw, size.height), holeOffset: yOffset);
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.color != color || old.glow != glow || old.yOffset != yOffset || old.g.height != g.height;
}

/// Righe del pavimento tra un posto e l'altro, e i colori della "calamita".
class _FloorGridPainter extends CustomPainter {
  _FloorGridPainter({required this.g, required this.count, required this.glowPositions, required this.glow, this.hover});
  final LevelGeometry g;
  final int count;
  final Set<int> glowPositions;
  final double glow;
  final DropHover? hover;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // Punto di fuga: le righe convergono un poco verso il fondo.
    double backX(double x) => cx + (x - cx) * 0.94;

    final h = hover;
    for (var pos = 0; pos < count; pos++) {
      final l = pos * g.colW;
      final r = l + g.colW;
      final cell = Path()
        ..moveTo(backX(l), g.floorBackY)
        ..lineTo(backX(r), g.floorBackY)
        ..lineTo(r, g.floorFrontY)
        ..lineTo(l, g.floorFrontY)
        ..close();
      Color? fill;
      if (h != null && pos >= h.start && pos < h.start + h.span) {
        fill = (h.ok ? TrovoColors.primary : TrovoColors.danger).withValues(alpha: 0.45);
      } else if (glow > 0 && glowPositions.contains(pos)) {
        fill = TrovoColors.found.withValues(alpha: 0.5 * glow);
      }
      if (fill != null) canvas.drawPath(cell, Paint()..color = fill);
    }

    final line = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..strokeWidth = 1.2;
    for (var pos = 1; pos < count; pos++) {
      final x = pos * g.colW;
      canvas.drawLine(Offset(backX(x), g.floorBackY), Offset(x, g.floorFrontY), line);
    }
  }

  @override
  bool shouldRepaint(_FloorGridPainter old) =>
      old.count != count || old.glow != glow || old.hover != hover || old.g.colW != g.colW || !setEquals(old.glowPositions, glowPositions);
}

class _DashedBoxPainter extends CustomPainter {
  _DashedBoxPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 6, metric.length)), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBoxPainter old) => old.color != color || old.radius != radius;
}
