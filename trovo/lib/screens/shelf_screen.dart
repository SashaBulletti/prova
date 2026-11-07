import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models.dart';
import '../store_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/fly.dart';
import '../widgets/labels_sheet.dart';
import '../widgets/photo_update.dart';
import '../widgets/sheets.dart';
import '../widgets/shelf3d.dart';
import '../widgets/shelf_art.dart';
import 'level_screen.dart';

const _capHeight = 14.0;

/// Lo scaffale in 3D: ogni piano è una fila di posti, e in ogni posto
/// le cose stanno in fila una dietro l'altra.
/// Se arrivi da una ricerca o da un QR, parte il "Faro" sul posto giusto.
class ShelfScreen extends StatefulWidget {
  const ShelfScreen({
    super.key,
    required this.shelfId,
    this.highlightLevelId,
    this.highlightItemId,
    this.highlightSlot,
  });

  final String shelfId;
  final String? highlightLevelId;
  final String? highlightItemId;

  /// Posto da illuminare (da 0), quando arrivi dal QR di un posto.
  final int? highlightSlot;

  @override
  State<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends State<ShelfScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _faro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  );
  final Map<String, GlobalKey> _levelKeys = {};
  final Set<String> _justAdded = {};
  DropHover? _hover;

  GlobalKey _keyFor(String id) => _levelKeys.putIfAbsent(id, GlobalKey.new);

  /// Intensità del bagliore: 3 impulsi, poi resta acceso.
  double get _glow {
    if (_faro.status == AnimationStatus.dismissed) return 0;
    if (Motion.reduced(context)) return 1;
    return 0.3 + 0.7 * math.cos(_faro.value * 3 * math.pi).abs();
  }

  @override
  void initState() {
    super.initState();
    if (widget.highlightLevelId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startFaro());
    }
  }

  Future<void> _startFaro() async {
    final ctx = _levelKeys[widget.highlightLevelId]?.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        alignment: 0.4,
        duration: Motion.of(context, 450),
        curve: Curves.easeInOutCubic,
      );
    }
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    _faro.forward(from: 0);
  }

  @override
  void dispose() {
    _faro.dispose();
    super.dispose();
  }

  Shelf? _findShelf() {
    for (final room in context.watchStore.rooms) {
      for (final shelf in room.shelves) {
        if (shelf.id == widget.shelfId) return shelf;
      }
    }
    return null;
  }

  void _addLevel(Shelf shelf) {
    final store = context.store;
    final index = store.addLevel(shelf);
    final level = shelf.levels[index];
    HapticFeedback.heavyImpact();
    setState(() => _justAdded.add(level.id));
    final delay = Motion.of(context, 120);
    final scroll = Motion.of(context, 350);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(delay);
      final ctx = _levelKeys[level.id]?.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(ctx, alignment: 0.5, duration: scroll, curve: Curves.easeOutCubic);
      }
    });
  }

  void _addAt(Room room, Shelf shelf, Level level, int index, int pos) {
    showAddItemSheet(
      context,
      target: LevelRef(room: room, shelf: shelf, level: level, levelIndex: index),
      position: pos,
      onAdded: (item, where, from) {
        final key = _levelKeys[where.level.id];
        if (key != null) flyEmoji(context, emoji: item.emoji, from: from, to: centerOf(key));
      },
    );
  }

  Future<void> _removeSlot(Level level, int pos) async {
    final s = context.s;
    final ok = await confirmDialog(context, s.removeSlotConfirm(pos + 1), confirmLabel: s.remove);
    if (!ok || !mounted) return;
    context.store.removeSlot(level, pos);
  }

  Future<void> _editItem(Room room, Shelf shelf, Level level, int index, Item item) async {
    final loc = ItemLocation(room: room, shelf: shelf, level: level, levelIndex: index, item: item);
    final result = await showEditItemSheet(context, loc);
    if (!mounted) return;
    final s = context.s;
    if (result == ItemEditResult.usedUp) {
      final store = context.store;
      final positions = store.removeItem(level, item);
      HapticFeedback.mediumImpact();
      showToast(
        context,
        '${item.emoji} ${s.removed(item.name)}',
        actionLabel: s.undo,
        onAction: () => store.restoreItem(level, item, positions),
      );
    } else if (result == ItemEditResult.moved) {
      showToast(context, s.moved(item.name));
    }
  }

  int _startFor(DragPayload p, Level to, int pos) =>
      (pos - p.grab).clamp(0, math.max(0, to.slotCount - p.span));

  void _onHover(DragPayload p, Level to, int pos) {
    final start = _startFor(p, to, pos);
    final ok = context.store.moveItemTo(p.item, p.level, to, start, dryRun: true);
    final next = DropHover(levelId: to.id, start: start, span: p.span, ok: ok);
    if (next != _hover) {
      HapticFeedback.selectionClick();
      setState(() => _hover = next);
    }
  }

  bool _onDrop(DragPayload p, Level to, int pos) {
    final start = _startFor(p, to, pos);
    final ok = context.store.moveItemTo(p.item, p.level, to, start);
    setState(() => _hover = null);
    if (ok) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
      showToast(context, context.s.noRoomHere);
    }
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final shelf = _findShelf();
    final s = context.s;
    final theme = Theme.of(context);
    if (shelf == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold();
    }
    final store = context.store;
    final room = store.roomOf(shelf);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ColorDot(color: TrovoColors.shelf(shelf.colorIndex), size: 16),
            const SizedBox(width: 10),
            Flexible(child: Text(shelf.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: s.photoUpdate,
            iconSize: 26,
            onPressed: () => runPhotoUpdate(context),
            icon: const Icon(Icons.photo_camera_rounded),
          ),
          PopupMenuButton<String>(
            iconSize: 26,
            onSelected: (v) async {
              if (v == 'edit') {
                final r = await showEditShelfSheet(context, room, shelf);
                if (r == ShelfEditResult.deleted && context.mounted) Navigator.of(context).pop();
              } else if (v == 'labels') {
                showLabelsSheet(context, shelf: shelf);
              } else if (v == 'photo') {
                runPhotoUpdate(context);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'labels', child: ListTile(leading: const Icon(Icons.qr_code_2_rounded), title: Text(s.labels))),
              PopupMenuItem(value: 'photo', child: ListTile(leading: const Icon(Icons.photo_camera_rounded), title: Text(s.photoUpdate))),
              PopupMenuItem(value: 'edit', child: ListTile(leading: const Icon(Icons.edit_rounded), title: Text(s.edit))),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedBuilder(
        animation: _faro,
        builder: (context, _) {
          final glow = _glow;
          var y = _capHeight;
          final rows = <Widget>[];
          for (var i = 0; i < shelf.levels.length; i++) {
            final level = shelf.levels[i];
            final isHi = level.id == widget.highlightLevelId;
            final glowPositions = !isHi
                ? const <int>{}
                : widget.highlightItemId != null
                    ? level.positionsOf(widget.highlightItemId!).toSet()
                    : {if (widget.highlightSlot != null) widget.highlightSlot!};
            Widget row = Level3DRow(
              key: _keyFor(level.id),
              shelf: shelf,
              level: level,
              number: shelf.levelNumber(i),
              yOffset: y,
              glow: isHi ? glow : 0,
              glowPositions: glowPositions,
              pulseItemId: isHi ? widget.highlightItemId : null,
              hover: _hover,
              onTapEmpty: (pos) => _addAt(room, shelf, level, i, pos),
              onLongPressEmpty: (pos) => _removeSlot(level, pos),
              onTapItem: (item) => _editItem(room, shelf, level, i, item),
              onAddSlot: () => store.addSlot(level),
              onOpenLevel: () {
                if (isHi) _faro.reset();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => LevelScreen(levelId: level.id)));
              },
              onHover: (p, pos) => _onHover(p, level, pos),
              onHoverEnd: () {
                if (_hover?.levelId == level.id) setState(() => _hover = null);
              },
              onDrop: (p, pos) => _onDrop(p, level, pos),
            );
            if (_justAdded.contains(level.id)) {
              row = row
                  .animate(onComplete: (_) => _justAdded.remove(level.id))
                  .fadeIn(duration: Motion.of(context, 200))
                  .slideX(begin: 1.0, curve: Curves.easeOutBack, duration: Motion.of(context, 480));
            }
            rows.add(KeyedSubtree(key: ValueKey(level.id), child: row));
            y += 140;
          }

          const sideGutters = EdgeInsets.only(left: LevelGeometry.tagW, right: LevelGeometry.addW);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '${room.emoji} ${room.name} · ${s.levelsCount(shelf.levels.length)} · ${s.itemsCount(shelf.itemCount)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                sliver: SliverToBoxAdapter(
                  child: Text('👆 ${s.dragToMove}', style: theme.textTheme.bodySmall),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                sliver: SliverToBoxAdapter(
                  child: AnimatedSize(
                    duration: Motion.of(context, 320),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        Padding(
                          padding: sideGutters,
                          child: SizedBox(
                            height: _capHeight,
                            width: double.infinity,
                            child: CustomPaint(painter: ShelfCapPainter(uprightWidth: LevelGeometry.uprightW)),
                          ),
                        ),
                        ...rows,
                        Padding(
                          padding: sideGutters,
                          child: SizedBox(
                            height: 26,
                            width: double.infinity,
                            child: CustomPaint(painter: ShelfFeetPainter(yOffset: y, uprightWidth: LevelGeometry.uprightW)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                sliver: SliverToBoxAdapter(
                  child: OutlinedButton.icon(
                    onPressed: shelf.levels.length >= 30 ? null : () => _addLevel(shelf),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(s.addLevel),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
