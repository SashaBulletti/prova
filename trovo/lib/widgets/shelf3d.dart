import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../icons.dart';

import '../models.dart';
import '../store_scope.dart';
import '../theme.dart';
import 'common.dart';
import 'shelf_art.dart' show paintUpright, paintGlassBoard;

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
    unit = (colW * 0.8).clamp(16.0, 50.0);
    step = unit * 0.18;
    floorDepth = unit * 0.32 + 6;
    height = math.max(124.0, top + unit + (maxVisible - 1) * step + floorDepth + edgeH + labelH + 4);
    floorFrontY = height - edgeH - labelH;
    floorBackY = floorFrontY - floorDepth;
  }

  static const tagW = 40.0;
  static const addW = 40.0;
  static const uprightW = 8.0;
  static const pad = 6.0;
  static const minColW = 26.0;
  static const edgeH = 6.0;
  static const labelH = 18.0;
  static const top = 10.0;

  /// Quante confezioni si vedono in fila, una dietro l'altra.
  static const maxVisible = 5;

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

/// Un piano dello scaffale in 3D: posti da sinistra a destra,
/// e in ogni posto le confezioni in fila, una dietro l'altra.
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
    this.dimmed = false,
  });

  final Shelf shelf;
  final Level level;
  final int number;
  final double yOffset;
  final double glow;
  final Set<int> glowPositions;
  final String? pulseItemId;
  final DropHover? hover;

  /// Durante il "Faro" gli altri piani si abbassano di luce.
  final bool dimmed;

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
    return AnimatedOpacity(
      opacity: dimmed ? 0.4 : 1,
      duration: Motion.of(context, 300),
      child: LayoutBuilder(builder: (context, c) {
        final g = LevelGeometry(c.maxWidth, level.slotCount);
        final columns = _Columns(row: this, g: g, color: color);
        return SizedBox(
          height: g.height,
          child: Row(
            children: [
              // Numero del piano: toccalo per aprire la lista.
              SizedBox(
                width: LevelGeometry.tagW,
                child: Align(
                  alignment: Alignment(0, (g.floorFrontY + 3) / g.height * 2 - 1),
                  child: Semantics(
                    button: true,
                    label: '${s.level(number)}, ${s.itemsCount(level.items.length)}',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onOpenLevel();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: LevelTag(number: number, color: color, size: 28, glow: glow),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: g.frameW,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _FramePainter(g: g, color: color, yOffset: yOffset, glow: glow)),
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
                child: Align(
                  alignment: Alignment(0, (g.floorFrontY - g.unit * 0.5) / g.height * 2 - 1),
                  child: Tooltip(
                    message: s.addSlot,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onAddSlot();
                      },
                      child: Container(
                        width: 30,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: const Icon(PIcons.plus, size: 18, color: TrovoColors.textMuted),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
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
    final duration = Motion.of(context, 300);

    children.add(Positioned.fill(
      child: CustomPaint(
        painter: _FloorPainter(
          g: g,
          count: level.slotCount,
          glowPositions: row.glowPositions,
          glow: row.glow,
          hover: row.hover?.levelId == level.id ? row.hover : null,
        ),
      ),
    ));

    for (final block in level.blocks) {
      final left = block.start * g.colW;
      final width = block.span * g.colW;
      // Etichetta sotto il bordo: nome dell'oggetto, o numero del posto libero.
      children.add(AnimatedPositioned(
        key: ValueKey('label-${block.item?.id ?? 'e${block.start}'}'),
        duration: duration,
        curve: Motion.standard,
        left: left,
        width: width,
        top: g.floorFrontY + LevelGeometry.edgeH + 2,
        height: LevelGeometry.labelH - 2,
        child: IgnorePointer(
          child: Center(
            child: Text(
              block.isEmpty ? '${block.start + 1}' : block.item!.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: TrovoTheme.fontFamily,
                fontWeight: FontWeight.w600,
                fontSize: block.isEmpty ? 11 : (width >= 64 ? 13 : 11.5),
                height: 1.1,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: block.isEmpty ? TrovoColors.textFaint : TrovoColors.text.withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      ));

      if (block.isEmpty) {
        children.add(AnimatedPositioned(
          key: ValueKey('empty-${block.start}'),
          duration: duration,
          curve: Motion.standard,
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
          tint: color,
          glow: glowing,
          pulse: item.id == row.pulseItemId ? row.glow : 0,
        );
        children.add(AnimatedPositioned(
          key: ValueKey('item-${item.id}'),
          duration: duration,
          curve: Motion.standard,
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

    // Bersagli per il trascinamento: sopra a tutto ma "trasparenti" ai tocchi.
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

/// Posto libero: un incavo con il + al centro.
class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.g, required this.glow, required this.onTap, required this.onLongPress});
  final LevelGeometry g;
  final double glow;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final size = g.unit * 0.9;
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
            padding: const EdgeInsets.only(bottom: 3),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.32), Colors.black.withValues(alpha: 0.12)],
                ),
                border: Border.all(
                  color: Color.lerp(Colors.white.withValues(alpha: 0.10), TrovoColors.found, glow)!,
                  width: glow > 0 ? 2 : 1,
                ),
                boxShadow: glow > 0
                    ? [BoxShadow(color: TrovoColors.found.withValues(alpha: 0.5 * glow), blurRadius: 20 * glow)]
                    : null,
              ),
              child: Icon(
                PIcons.plus,
                size: size * 0.4,
                color: Color.lerp(Colors.white.withValues(alpha: 0.35), TrovoColors.found, glow),
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
          offset: Offset(-(_grab + 0.5) * g.colW, -g.floorFrontY * 0.8),
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              width: widget.span * g.colW,
              height: g.floorFrontY,
              child: Transform.scale(scale: 1.08, child: widget.visual),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.2, child: widget.visual),
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

/// Le confezioni di un oggetto in fila, dalla più lontana alla più vicina.
class _BlockVisual extends StatelessWidget {
  const _BlockVisual({
    required this.item,
    required this.span,
    required this.g,
    required this.tint,
    required this.glow,
    required this.pulse,
  });

  final Item item;
  final int span;
  final LevelGeometry g;
  final Color tint;
  final double glow;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final perColumn = splitQuantity(item.quantity, span);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var c = 0; c < span; c++)
          Positioned(
            left: c * g.colW,
            width: g.colW,
            top: 0,
            bottom: 0,
            child: _Column(item: item, count: perColumn[c], g: g, tint: tint, glow: glow, pulse: c == 0 ? pulse : 0),
          ),
        if (item.quantity > 1)
          Positioned(
            right: math.max(0, (g.colW - g.unit) / 2 - 6),
            bottom: g.unit - 8,
            child: QuantityBadge(quantity: item.quantity),
          ),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.item, required this.count, required this.g, required this.tint, required this.glow, required this.pulse});

  final Item item;
  final int count;
  final LevelGeometry g;
  final Color tint;
  final double glow;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final visible = math.min(count, LevelGeometry.maxVisible);
    final extra = count - visible;
    final units = <Widget>[];
    // Ombra di contatto sotto la fila.
    units.add(Positioned(
      bottom: 0,
      left: (g.colW - g.unit) / 2,
      child: Container(
        width: g.unit,
        height: 6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6)],
        ),
      ),
    ));
    // Dal fondo verso davanti: quella davanti copre le altre.
    for (var j = visible - 1; j >= 0; j--) {
      final scale = math.pow(0.92, j).toDouble();
      final size = g.unit * scale;
      units.add(Positioned(
        bottom: 3 + j * g.step,
        left: (g.colW - size) / 2,
        child: Transform.scale(
          scale: j == 0 ? 1 + 0.14 * pulse : 1,
          child: GlassTile(
            size: size,
            emoji: item.emoji,
            tint: tint,
            darken: 0.18 * j,
            glow: j == 0 ? glow : 0,
          ),
        ),
      ));
    }
    if (extra > 0) {
      units.add(Positioned(
        bottom: 3 + visible * g.step + g.unit * 0.62,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$extra',
              style: const TextStyle(
                fontFamily: TrovoTheme.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: TrovoColors.textMuted,
              ),
            ),
          ),
        ),
      ));
    }
    return Stack(clipBehavior: Clip.none, children: units);
  }
}

/// Cornice del piano: luce dall'alto, ripiano in vetro fumé, bordo luminoso, montanti.
class _FramePainter extends CustomPainter {
  _FramePainter({required this.g, required this.color, required this.yOffset, required this.glow});
  final LevelGeometry g;
  final Color color;
  final double yOffset;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    const uw = LevelGeometry.uprightW;
    final inner = Rect.fromLTRB(uw, 0, size.width - uw, g.floorFrontY);

    // Luce morbida dall'alto (una sola luce, da in alto a sinistra).
    canvas.drawRect(
      inner,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -1.2),
          radius: 1.3,
          colors: [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0)],
        ).createShader(inner),
    );
    if (glow > 0) {
      canvas.drawRect(
        inner,
        Paint()
          ..shader = RadialGradient(
            center: Alignment.bottomCenter,
            radius: 1.1,
            colors: [TrovoColors.found.withValues(alpha: 0.10 * glow), TrovoColors.found.withValues(alpha: 0)],
          ).createShader(inner),
      );
    }

    paintGlassBoard(
      canvas,
      left: uw - 2,
      right: size.width - uw + 2,
      backY: g.floorBackY,
      frontY: g.floorFrontY,
      edgeH: LevelGeometry.edgeH,
      color: color,
      glow: glow * 0.6,
      ledH: LevelGeometry.labelH + 6,
    );

    paintUpright(canvas, Rect.fromLTWH(0, 0, uw, size.height), holeOffset: yOffset);
    paintUpright(canvas, Rect.fromLTWH(size.width - uw, 0, uw, size.height), holeOffset: yOffset);
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.color != color || old.glow != glow || old.yOffset != yOffset || old.g.height != g.height;
}

/// Divisioni del ripiano tra un posto e l'altro, la "calamita" e il cono di luce del Faro.
class _FloorPainter extends CustomPainter {
  _FloorPainter({required this.g, required this.count, required this.glowPositions, required this.glow, this.hover});
  final LevelGeometry g;
  final int count;
  final Set<int> glowPositions;
  final double glow;
  final DropHover? hover;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    double backX(double x) => cx + (x - cx) * 0.95;

    final h = hover;
    for (var pos = 0; pos < count; pos++) {
      final l = pos * g.colW;
      final r = l + g.colW;
      final cell = Path()
        ..moveTo(backX(l) + 1, g.floorBackY)
        ..lineTo(backX(r) - 1, g.floorBackY)
        ..lineTo(r - 1, g.floorFrontY)
        ..lineTo(l + 1, g.floorFrontY)
        ..close();
      if (h != null && pos >= h.start && pos < h.start + h.span) {
        final c = h.ok ? TrovoColors.primary : TrovoColors.danger;
        canvas.drawPath(cell, Paint()..color = c.withValues(alpha: 0.40));
        canvas.drawPath(
          cell,
          Paint()
            ..color = c.withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      } else if (glow > 0 && glowPositions.contains(pos)) {
        // Cono di luce dall'alto sul posto trovato.
        final cone = Path()
          ..moveTo(l + g.colW * 0.35, 0)
          ..lineTo(r - g.colW * 0.35, 0)
          ..lineTo(r, g.floorFrontY)
          ..lineTo(l, g.floorFrontY)
          ..close();
        canvas.drawPath(
          cone,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [TrovoColors.found.withValues(alpha: 0), TrovoColors.found.withValues(alpha: 0.22 * glow)],
            ).createShader(Rect.fromLTRB(l, 0, r, g.floorFrontY)),
        );
        canvas.drawPath(cell, Paint()..color = TrovoColors.found.withValues(alpha: 0.35 * glow));
      }
    }

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var pos = 1; pos < count; pos++) {
      final x = pos * g.colW;
      canvas.drawLine(Offset(backX(x), g.floorBackY), Offset(x, g.floorFrontY), line);
    }
  }

  @override
  bool shouldRepaint(_FloorPainter old) =>
      old.count != count || old.glow != glow || old.hover != hover || old.g.colW != g.colW || !setEquals(old.glowPositions, glowPositions);
}
