import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store_scope.dart';
import '../theme.dart';
import 'wallpaper.dart';

/// Disposizione della casa sulla mappa (in "metri" circa).
class HouseLayout {
  HouseLayout(this.rooms, this.furniture);
  final Map<String, Rect> rooms;
  final Map<String, Rect> furniture;

  Rect get bounds {
    if (rooms.isEmpty) return const Rect.fromLTWH(0, 0, 10, 8);
    var r = rooms.values.first;
    for (final x in rooms.values) {
      r = r.expandToInclude(x);
    }
    return r;
  }
}

/// Ingombro di un mobile visto dall'alto (larghezza × profondità).
Size footprint(Shelf shelf) => switch (shelf.kind) {
  FurnitureKind.shelf => Size(
    math.max(
      1.0,
      shelf.levels.fold<int>(0, (m, l) => math.max(m, l.slotCount)) * 0.3,
    ),
    0.45,
  ),
  FurnitureKind.drawers => const Size(1.0, 0.6),
  FurnitureKind.wardrobe => const Size(2.0, 0.65),
  FurnitureKind.cubes => Size(math.max(0.8, shelf.gridColumns * 0.4), 0.4),
  FurnitureKind.cabinet => const Size(0.9, 0.55),
};

/// Calcola dove stanno stanze e mobili. Se l'utente li ha spostati, usa le sue posizioni;
/// altrimenti li mette in ordine da solo (stanze su due colonne, mobili lungo i muri).
HouseLayout computeLayout(List<Room> rooms, {int columns = 2}) {
  final roomRects = <String, Rect>{};
  final furn = <String, Rect>{};
  const roomW = 6.0;
  const gap = 0.6;
  var rowY = 0.0;
  var rowH = 0.0;
  for (var i = 0; i < rooms.length; i++) {
    final room = rooms[i];
    final col = i % columns;
    if (col == 0 && i > 0) {
      rowY += rowH + gap;
      rowH = 0;
    }
    final autoH = math.max(4.0, 2.6 + (room.shelves.length / 3).ceil() * 1.1);
    final box = room.mapBox;
    final rect = box != null
        ? Rect.fromLTWH(box.x, box.y, box.w, box.h)
        : Rect.fromLTWH(col * (roomW + gap), rowY, roomW, autoH);
    rowH = math.max(rowH, rect.height);
    roomRects[room.id] = rect;

    // Mobili: posizione salvata (relativa alla stanza) oppure lungo i muri.
    const margin = 0.2;
    var cursorX = margin;
    var wall = 0; // 0 = muro in alto, 1 = muro in basso, 2+ = file nel mezzo
    var midY = 1.4;
    for (final shelf in room.shelves) {
      final mb = shelf.mapBox;
      if (mb != null) {
        furn[shelf.id] = Rect.fromLTWH(
          rect.left + mb.x * rect.width,
          rect.top + mb.y * rect.height,
          mb.w * rect.width,
          mb.h * rect.height,
        );
        continue;
      }
      final f = footprint(shelf);
      final fw = math.min(f.width, rect.width - 2 * margin);
      if (cursorX + fw > rect.width - margin) {
        wall++;
        cursorX = margin;
        if (wall >= 2) midY += 1.0;
      }
      final y = switch (wall) {
        0 => margin,
        1 => rect.height - margin - f.height,
        _ => math.min(midY, rect.height - margin - f.height),
      };
      furn[shelf.id] = Rect.fromLTWH(
        rect.left + cursorX,
        rect.top + y,
        fw,
        f.height,
      );
      cursorX += fw + 0.25;
    }
  }
  return HouseLayout(roomRects, furn);
}

/// La casa vista dall'alto, come la mappa di un robot aspirapolvere.
/// Tocca un mobile per aprirlo. In modalità "modifica" trascini stanze e mobili.
class HouseMapView extends StatefulWidget {
  const HouseMapView({
    super.key,
    required this.editing,
    required this.onOpenShelf,
    this.onSelectRoom,
    this.highlightShelfId,
    this.highlightRoomId,
  });

  final bool editing;
  final void Function(Shelf shelf) onOpenShelf;
  final void Function(Room room)? onSelectRoom;
  final String? highlightShelfId;
  final String? highlightRoomId;

  @override
  State<HouseMapView> createState() => _HouseMapViewState();
}

class _HouseMapViewState extends State<HouseMapView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  final _transform = TransformationController();

  /// Posizioni mentre trascini (in metri). Si salvano quando lasci.
  final Map<String, Rect> _dragRooms = {};
  final Map<String, Rect> _dragFurn = {};

  @override
  void initState() {
    super.initState();
    if (widget.highlightShelfId != null) _pulse.repeat();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted && _pulse.isAnimating) _pulse.stop();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _transform.dispose();
    super.dispose();
  }

  /// Quando inizi a sistemare la mappa, le posizioni automatiche diventano fisse.
  int _columns = 1;

  void _materialize(HouseLayout layout) {
    final store = context.store;
    for (final room in store.rooms) {
      final r = layout.rooms[room.id]!;
      room.mapBox ??= MapBox(r.left, r.top, r.width, r.height);
      for (final shelf in room.shelves) {
        final f = layout.furniture[shelf.id];
        if (f == null || shelf.mapBox != null) continue;
        shelf.mapBox = MapBox(
          (f.left - r.left) / r.width,
          (f.top - r.top) / r.height,
          f.width / r.width,
          f.height / r.height,
        );
      }
    }
  }

  @override
  void didUpdateWidget(HouseMapView old) {
    super.didUpdateWidget(old);
    if (widget.editing && !old.editing) {
      _materialize(computeLayout(context.store.rooms, columns: _columns));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watchStore;
    final s = context.s;
    if (store.rooms.isEmpty) {
      return Center(
        child: Text(s.mapEmpty, style: Theme.of(context).textTheme.bodyLarge),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        // Sul telefono le stanze vanno una sotto l'altra, grandi; sul tablet su due colonne.
        _columns = c.maxWidth < 600 ? 1 : 2;
        final layout = computeLayout(store.rooms, columns: _columns);
        final rooms = {...layout.rooms, ..._dragRooms};
        final furn = {...layout.furniture, ..._dragFurn};
        final b = layout.bounds;
        const pad = 20.0;
        const padTop = 60.0;
        final scale = ((c.maxWidth - 2 * pad) / b.width).clamp(24.0, 90.0);
        final canvasW = b.width * scale + 2 * pad;
        final canvasH = math.max(
          b.height * scale + padTop + pad + 80,
          c.maxHeight,
        );
        Offset toPx(double x, double y) =>
            Offset(pad + (x - b.left) * scale, padTop + (y - b.top) * scale);
        Rect rectPx(Rect r) =>
            Rect.fromPoints(toPx(r.left, r.top), toPx(r.right, r.bottom));

        final children = <Widget>[
          Positioned.fill(child: CustomPaint(painter: _DotsPainter())),
        ];

        for (var i = 0; i < store.rooms.length; i++) {
          final room = store.rooms[i];
          final r = rooms[room.id]!;
          final px = rectPx(r);
          final tint = TrovoColors.shelf(i);
          final selected = room.id == widget.highlightRoomId;
          final dimmed =
              widget.highlightShelfId != null &&
              !room.shelves.any((sh) => sh.id == widget.highlightShelfId);

          children.add(
            Positioned.fromRect(
              rect: px,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.editing
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        widget.onSelectRoom?.call(room);
                      },
                onPanUpdate: !widget.editing
                    ? null
                    : (d) => setState(() {
                        final cur = _dragRooms[room.id] ?? r;
                        final next = cur.shift(d.delta / scale);
                        _dragRooms[room.id] = next;
                        // I mobili si spostano con la stanza.
                        for (final sh in room.shelves) {
                          final f = _dragFurn[sh.id] ?? layout.furniture[sh.id];
                          if (f != null) {
                            _dragFurn[sh.id] = f.shift(d.delta / scale);
                          }
                        }
                      }),
                onPanEnd: !widget.editing ? null : (_) => _commitRoom(room),
                child: AnimatedOpacity(
                  duration: Motion.of(context, 300),
                  opacity: dimmed ? 0.45 : 1,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Color.lerp(TrovoColors.surface, tint, 0.06),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selected
                            ? TrovoColors.primary
                            : PaperColors.ink.withValues(alpha: 0.85),
                        width: selected ? 3.5 : 3,
                      ),
                    ),
                    foregroundDecoration: null,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.55,
                            child: CustomPaint(
                              painter: WallpaperPainter(
                                wallpaperOf(room),
                                scale: 0.5,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: FittedBox(
                              child: Text(
                                '${room.emoji} ${room.name}',
                                style: TextStyle(
                                  fontFamily: TrovoTheme.fontFamily,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: TrovoColors.text.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

          // Maniglia per allargare la stanza.
          if (widget.editing) {
            children.add(
              Positioned(
                left: px.right - 18,
                top: px.bottom - 18,
                width: 36,
                height: 36,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (d) => setState(() {
                    final cur = _dragRooms[room.id] ?? r;
                    _dragRooms[room.id] = Rect.fromLTWH(
                      cur.left,
                      cur.top,
                      math.max(2.0, cur.width + d.delta.dx / scale),
                      math.max(2.0, cur.height + d.delta.dy / scale),
                    );
                  }),
                  onPanEnd: (_) => _commitRoom(room),
                  child: Center(
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: TrovoColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: TrovoColors.background,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.open_in_full_rounded,
                        size: 12,
                        color: TrovoColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        }

        // Mobili visti dall'alto.
        for (final room in store.rooms) {
          final roomRect = rooms[room.id]!;
          for (final shelf in room.shelves) {
            final f = furn[shelf.id];
            if (f == null) continue;
            final px = rectPx(f);
            final hi = shelf.id == widget.highlightShelfId;
            children.add(
              Positioned.fromRect(
                rect: px,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (widget.editing) return;
                    HapticFeedback.selectionClick();
                    widget.onOpenShelf(shelf);
                  },
                  onDoubleTap: !widget.editing
                      ? null
                      : () {
                          // Ruota di 90°: scambia larghezza e profondità.
                          final cur = _dragFurn[shelf.id] ?? f;
                          final c = cur.center;
                          _dragFurn[shelf.id] = Rect.fromCenter(
                            center: c,
                            width: cur.height,
                            height: cur.width,
                          );
                          _commitFurniture(room, shelf, roomRect);
                        },
                  onPanUpdate: !widget.editing
                      ? null
                      : (d) => setState(() {
                          final cur = _dragFurn[shelf.id] ?? f;
                          var next = cur.shift(d.delta / scale);
                          // Resta dentro la stanza.
                          final dx = next.left < roomRect.left
                              ? roomRect.left - next.left
                              : (next.right > roomRect.right
                                    ? roomRect.right - next.right
                                    : 0.0);
                          final dy = next.top < roomRect.top
                              ? roomRect.top - next.top
                              : (next.bottom > roomRect.bottom
                                    ? roomRect.bottom - next.bottom
                                    : 0.0);
                          next = next.shift(Offset(dx, dy));
                          _dragFurn[shelf.id] = next;
                        }),
                  onPanEnd: !widget.editing
                      ? null
                      : (_) => _commitFurniture(room, shelf, roomRect),
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) => CustomPaint(
                      painter: _FurnitureTopPainter(
                        shelf: shelf,
                        color: TrovoColors.shelf(shelf.colorIndex),
                        highlight: hi ? 1 : 0,
                        pulse: hi ? _pulse.value : 0,
                        editing: widget.editing,
                      ),
                    ),
                  ),
                ),
              ),
            );
            // Nome sotto il mobile.
            if (px.width > 36) {
              children.add(
                Positioned(
                  left: px.left - 20,
                  width: px.width + 40,
                  top: px.bottom + 2,
                  child: IgnorePointer(
                    child: Text(
                      shelf.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: TrovoTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: hi ? TrovoColors.found : TrovoColors.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }
          }
        }

        return InteractiveViewer(
          transformationController: _transform,
          constrained: false,
          minScale: 0.5,
          maxScale: 4,
          panEnabled: !widget.editing,
          boundaryMargin: const EdgeInsets.all(200),
          child: SizedBox(
            width: math.max(canvasW, c.maxWidth),
            height: canvasH,
            child: Stack(children: children),
          ),
        );
      },
    );
  }

  void _commitRoom(Room room) {
    final store = context.store;
    final r = _dragRooms.remove(room.id);
    if (r == null) return;
    // I mobili restano dove sono rispetto alla stanza (posizione relativa).
    for (final sh in room.shelves) {
      _dragFurn.remove(sh.id);
      final mb = sh.mapBox;
      if (mb != null) {
        // Se la stanza cambia misura, il mobile resta dentro.
        mb.x = mb.x.clamp(0.0, math.max(0.0, 1 - mb.w));
        mb.y = mb.y.clamp(0.0, math.max(0.0, 1 - mb.h));
      }
    }
    store.setRoomMap(room, MapBox(r.left, r.top, r.width, r.height));
    HapticFeedback.lightImpact();
  }

  void _commitFurniture(Room room, Shelf shelf, Rect roomRect) {
    final f = _dragFurn.remove(shelf.id);
    if (f == null) return;
    context.store.setShelfMap(
      shelf,
      MapBox(
        ((f.left - roomRect.left) / roomRect.width).clamp(0.0, 1.0),
        ((f.top - roomRect.top) / roomRect.height).clamp(0.0, 1.0),
        (f.width / roomRect.width).clamp(0.02, 1.0),
        (f.height / roomRect.height).clamp(0.02, 1.0),
      ),
    );
    HapticFeedback.lightImpact();
    setState(() {});
  }
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = PaperColors.ink.withValues(alpha: 0.10);
    for (var x = 8.0; x < size.width; x += 16) {
      for (var y = 8.0; y < size.height; y += 16) {
        canvas.drawCircle(Offset(x, y), 1, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Un mobile visto dall'alto: rettangolo nel suo colore, con i dettagli del tipo.
class _FurnitureTopPainter extends CustomPainter {
  _FurnitureTopPainter({
    required this.shelf,
    required this.color,
    required this.highlight,
    required this.pulse,
    required this.editing,
  });

  final Shelf shelf;
  final Color color;
  final double highlight;
  final double pulse;
  final bool editing;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(4));

    if (highlight > 0) {
      // Anelli che si allargano: "è qui!"
      for (final k in [0.0, 0.5]) {
        final t = (pulse + k) % 1.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            r.inflate(4 + 26 * t),
            Radius.circular(6 + 20 * t),
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = TrovoColors.found.withValues(alpha: (1 - t) * 0.8),
        );
      }
    }

    canvas.drawRRect(
      rr.shift(const Offset(0, 2)),
      Paint()..color = PaperColors.ink.withValues(alpha: 0.16),
    );
    canvas.drawRRect(
      rr,
      Paint()..color = Color.lerp(color, Colors.white, 0.35)!,
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlight > 0 ? 2.5 : 1.5
        ..color = highlight > 0
            ? TrovoColors.found
            : PaperColors.ink.withValues(alpha: 0.85),
    );

    final line = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final horizontal = size.width >= size.height;
    final long = horizontal ? size.width : size.height;
    final short = horizontal ? size.height : size.width;
    void across(double t) {
      if (horizontal) {
        canvas.drawLine(Offset(t, 2), Offset(t, size.height - 2), line);
      } else {
        canvas.drawLine(Offset(2, t), Offset(size.width - 2, t), line);
      }
    }

    switch (shelf.kind) {
      case FurnitureKind.shelf:
        // Dall'alto si vedono i montanti agli angoli.
        final post = Paint()..color = TrovoColors.metalLight;
        final d = math.min(4.0, short * 0.3);
        for (final o in [
          Offset.zero,
          Offset(size.width - d, 0),
          Offset(0, size.height - d),
          Offset(size.width - d, size.height - d),
        ]) {
          canvas.drawRect(o & Size(d, d), post);
        }
      case FurnitureKind.cubes:
        final n = math.max(1, shelf.gridColumns);
        for (var i = 1; i < n; i++) {
          across(long * i / n);
        }
      case FurnitureKind.wardrobe:
        // Asta e grucce viste dall'alto.
        final rod = Paint()
          ..color = TrovoColors.metalLight
          ..strokeWidth = 1.5;
        if (horizontal) {
          canvas.drawLine(
            Offset(4, size.height / 2),
            Offset(size.width - 4, size.height / 2),
            rod,
          );
          for (var x = 8.0; x < size.width - 6; x += 7) {
            canvas.drawLine(
              Offset(x, size.height * 0.25),
              Offset(x + 2, size.height * 0.75),
              line,
            );
          }
        } else {
          canvas.drawLine(
            Offset(size.width / 2, 4),
            Offset(size.width / 2, size.height - 4),
            rod,
          );
          for (var y = 8.0; y < size.height - 6; y += 7) {
            canvas.drawLine(
              Offset(size.width * 0.25, y),
              Offset(size.width * 0.75, y + 2),
              line,
            );
          }
        }
      case FurnitureKind.drawers:
      case FurnitureKind.cabinet:
        // Il lato con le maniglie.
        final h = Paint()
          ..color = TrovoColors.metalLight
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        if (horizontal) {
          canvas.drawLine(
            Offset(size.width * 0.35, size.height - 3),
            Offset(size.width * 0.65, size.height - 3),
            h,
          );
        } else {
          canvas.drawLine(
            Offset(size.width - 3, size.height * 0.35),
            Offset(size.width - 3, size.height * 0.65),
            h,
          );
        }
    }

    // Quante cose ci sono: un pallino col numero.
    final count = shelf.itemCount;
    if (count > 0 && short >= 14) {
      final tp = TextPainter(
        text: TextSpan(
          text: '$count',
          style: TextStyle(
            fontFamily: TrovoTheme.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: math.min(12, short * 0.6),
            color: TrovoColors.text,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, r.center - Offset(tp.width / 2, tp.height / 2));
    }

    if (editing) {
      canvas.drawRRect(
        rr.inflate(2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = TrovoColors.primary.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(_FurnitureTopPainter old) => true;
}
