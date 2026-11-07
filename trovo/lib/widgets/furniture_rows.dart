import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store_scope.dart';
import '../theme.dart';
import 'common.dart';
import 'furniture_art.dart';
import 'shelf3d.dart';

/// Un cassetto visto di fronte: maniglia, filo colorato, anteprima di cosa c'è dentro.
/// Toccalo per aprirlo. Trascinaci sopra un oggetto per metterlo dentro.
class DrawerRow extends StatefulWidget {
  const DrawerRow({
    super.key,
    required this.shelf,
    required this.level,
    required this.number,
    required this.onOpen,
    required this.onDrop,
    this.glow = 0,
    this.pulseItemId,
  });

  final Shelf shelf;
  final Level level;
  final int number;
  final double glow;
  final String? pulseItemId;
  final VoidCallback onOpen;
  final bool Function(DragPayload payload) onDrop;

  @override
  State<DrawerRow> createState() => _DrawerRowState();
}

class _DrawerRowState extends State<DrawerRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final level = widget.level;
    final color = TrovoColors.level(level.colorIndex);
    final body = TrovoColors.shelf(widget.shelf.colorIndex);
    final glow = widget.glow;
    const height = 96.0;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          SizedBox(
            width: LevelGeometry.tagW,
            child: Center(
              child: GestureDetector(
                onTap: widget.onOpen,
                child: LevelTag(number: widget.number, color: color, size: 32, glow: glow),
              ),
            ),
          ),
          Expanded(
            child: CustomPaint(
              painter: _SidesPainter(body),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(LevelGeometry.uprightW + 3, 5, LevelGeometry.uprightW + 3, 5),
                child: DragTarget<DragPayload>(
                  onWillAcceptWithDetails: (d) {
                    if (!_hover) HapticFeedback.selectionClick();
                    setState(() => _hover = true);
                    return true;
                  },
                  onLeave: (_) => setState(() => _hover = false),
                  onAcceptWithDetails: (d) {
                    setState(() => _hover = false);
                    widget.onDrop(d.data);
                  },
                  builder: (context, _, _) => Semantics(
                    button: true,
                    label: '${s.compartment(level.kind, widget.number)}, ${s.itemsCount(level.items.length)}',
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onOpen();
                      },
                      child: AnimatedContainer(
                        duration: Motion.of(context, 180),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.lerp(TrovoColors.surfaceHigher, body, 0.22)!,
                              Color.lerp(TrovoColors.surfaceHigh, body, 0.12)!,
                            ],
                          ),
                          border: Border.all(
                            color: _hover
                                ? TrovoColors.primary
                                : (glow > 0
                                    ? TrovoColors.found.withValues(alpha: glow)
                                    : Colors.black.withValues(alpha: 0.35)),
                            width: _hover || glow > 0 ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 3)),
                            if (glow > 0) BoxShadow(color: TrovoColors.found.withValues(alpha: 0.5 * glow), blurRadius: 20 * glow),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Filo colorato in alto: il colore del cassetto.
                            Positioned(
                              left: 10,
                              right: 10,
                              top: 0,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Color.lerp(color, TrovoColors.found, glow),
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                                ),
                              ),
                            ),
                            // Maniglia.
                            Positioned(
                              top: 12,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  width: 56,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [TrovoColors.metalLight, TrovoColors.metalDark],
                                    ),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 3, offset: const Offset(0, 2))],
                                  ),
                                ),
                              ),
                            ),
                            // Anteprima del contenuto.
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 8,
                              child: LayoutBuilder(builder: (context, c) {
                                final items = level.items;
                                if (items.isEmpty) {
                                  return Text(
                                    '${s.itemsCount(0)} · ${s.openDrawer}',
                                    style: theme.textTheme.bodySmall,
                                  );
                                }
                                const tile = 34.0;
                                final fit = math.max(1, ((c.maxWidth - 70) / (tile + 6)).floor());
                                final shown = items.take(fit).toList();
                                return Row(
                                  children: [
                                    for (final it in shown)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: Transform.scale(
                                          scale: it.id == widget.pulseItemId ? 1 + 0.18 * glow : 1,
                                          child: ItemSticker(
                                            item: it,
                                            size: tile,
                                            glow: it.id == widget.pulseItemId ? glow : 0,
                                          ),
                                        ),
                                      ),
                                    if (items.length > shown.length)
                                      Text('+${items.length - shown.length}', style: theme.textTheme.titleSmall),
                                    const Spacer(),
                                    Text(s.itemsCount(items.length), style: theme.textTheme.bodySmall),
                                  ],
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: LevelGeometry.addW),
        ],
      ),
    );
  }
}

class _SidesPainter extends CustomPainter {
  _SidesPainter(this.tint);
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    const uw = LevelGeometry.uprightW;
    // Fondo del vano, dietro il cassetto.
    canvas.drawRect(Rect.fromLTRB(uw, 0, size.width - uw, size.height), Paint()..color = Colors.black.withValues(alpha: 0.30));
    paintPanelSide(canvas, Rect.fromLTWH(0, 0, uw, size.height), tint, left: true);
    paintPanelSide(canvas, Rect.fromLTWH(size.width - uw, 0, uw, size.height), tint, left: false);
  }

  @override
  bool shouldRepaint(_SidesPainter old) => old.tint != tint;
}

/// Libreria a cubi: griglia di vani quadrati, ognuno col suo numero.
class CubesGrid extends StatelessWidget {
  const CubesGrid({
    super.key,
    required this.shelf,
    required this.keyFor,
    required this.onOpen,
    required this.onDrop,
    this.highlightLevelId,
    this.pulseItemId,
    this.glow = 0,
  });

  final Shelf shelf;
  final GlobalKey Function(String levelId) keyFor;
  final void Function(Level level, int index) onOpen;
  final bool Function(Level level, DragPayload payload) onDrop;
  final String? highlightLevelId;
  final String? pulseItemId;
  final double glow;

  @override
  Widget build(BuildContext context) {
    final cols = math.max(1, shelf.gridColumns);
    final body = TrovoColors.shelf(shelf.colorIndex);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LevelGeometry.tagW - 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(TrovoColors.surfaceHigher, body, 0.4)!, Color.lerp(TrovoColors.surface, body, 0.25)!],
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 8))],
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: shelf.levels.length,
          itemBuilder: (context, i) {
            final level = shelf.levels[i];
            return _CubeCell(
              key: keyFor(level.id),
              level: level,
              number: shelf.levelNumber(i),
              glow: level.id == highlightLevelId ? glow : 0,
              pulseItemId: level.id == highlightLevelId ? pulseItemId : null,
              onOpen: () => onOpen(level, i),
              onDrop: (p) => onDrop(level, p),
            );
          },
        ),
      ),
    );
  }
}

class _CubeCell extends StatefulWidget {
  const _CubeCell({
    super.key,
    required this.level,
    required this.number,
    required this.glow,
    required this.onOpen,
    required this.onDrop,
    this.pulseItemId,
  });

  final Level level;
  final int number;
  final double glow;
  final String? pulseItemId;
  final VoidCallback onOpen;
  final bool Function(DragPayload payload) onDrop;

  @override
  State<_CubeCell> createState() => _CubeCellState();
}

class _CubeCellState extends State<_CubeCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final level = widget.level;
    final color = TrovoColors.level(level.colorIndex);
    final glow = widget.glow;
    return DragTarget<DragPayload>(
      onWillAcceptWithDetails: (d) {
        if (!_hover) HapticFeedback.selectionClick();
        setState(() => _hover = true);
        return true;
      },
      onLeave: (_) => setState(() => _hover = false),
      onAcceptWithDetails: (d) {
        setState(() => _hover = false);
        widget.onDrop(d.data);
      },
      builder: (context, _, _) => Semantics(
        button: true,
        label: '${s.compartment(level.kind, widget.number)}, ${s.itemsCount(level.items.length)}',
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onOpen();
          },
          child: AnimatedContainer(
            duration: Motion.of(context, 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.55), Colors.black.withValues(alpha: 0.30)],
              ),
              border: Border.all(
                color: _hover
                    ? TrovoColors.primary
                    : (glow > 0 ? TrovoColors.found.withValues(alpha: glow) : color.withValues(alpha: 0.55)),
                width: _hover || glow > 0 ? 2.5 : 1.5,
              ),
              boxShadow: glow > 0 ? [BoxShadow(color: TrovoColors.found.withValues(alpha: 0.5 * glow), blurRadius: 18 * glow)] : null,
            ),
            child: LayoutBuilder(builder: (context, c) {
              final tile = math.min(c.maxWidth * 0.38, 46.0);
              final items = level.items;
              return Stack(
                children: [
                  Positioned(left: 6, top: 6, child: LevelTag(number: widget.number, color: color, size: 22, glow: glow)),
                  if (items.isEmpty)
                    Center(child: Icon(Icons.add_rounded, color: TrovoColors.metal, size: tile * 0.7))
                  else
                    Positioned(
                      left: 6,
                      right: 6,
                      bottom: 6,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final it in items.take(c.maxWidth > 110 ? 4 : 2))
                            ItemSticker(
                              item: it,
                              size: tile,
                              glow: it.id == widget.pulseItemId ? glow : 0,
                            ),
                          if (items.length > (c.maxWidth > 110 ? 4 : 2))
                            Text(
                              '+${items.length - (c.maxWidth > 110 ? 4 : 2)}',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                        ],
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
