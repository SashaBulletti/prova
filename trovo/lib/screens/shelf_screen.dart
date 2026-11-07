import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models.dart';
import '../store_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/fly.dart';
import '../widgets/sheets.dart';
import '../widgets/shelf_art.dart';
import 'level_screen.dart';

const _levelHeight = 128.0;
const _capHeight = 14.0;

/// Lo scaffale grande, visto di fronte, con tutti i suoi piani.
/// Se arrivi da una ricerca, parte l'animazione "Faro" sul piano giusto.
class ShelfScreen extends StatefulWidget {
  const ShelfScreen({super.key, required this.shelfId, this.highlightLevelId, this.highlightItemId});

  final String shelfId;
  final String? highlightLevelId;
  final String? highlightItemId;

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
  final Set<String> _removing = {};

  GlobalKey _keyFor(String id) => _levelKeys.putIfAbsent(id, GlobalKey.new);

  /// Intensità del bagliore: 3 impulsi, poi resta acceso.
  double get _glow {
    if (Motion.reduced(context)) return 1;
    final t = _faro.value;
    if (_faro.status == AnimationStatus.dismissed) return 0;
    return 0.3 + 0.7 * math.cos(t * 3 * math.pi).abs();
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

  Future<void> _levelMenu(Shelf shelf, Level level, int index) async {
    final s = context.s;
    HapticFeedback.mediumImpact();
    final number = shelf.levelNumber(index);
    final ok = await confirmDialog(context, s.deleteLevelConfirm(number, level.items.length));
    if (!ok || !mounted) return;
    setState(() => _removing.add(level.id));
  }

  void _quickAdd(Room room, Shelf shelf, Level level, int index) {
    showAddItemSheet(
      context,
      target: LevelRef(room: room, shelf: shelf, level: level, levelIndex: index),
      onAdded: (item, where, from) {
        final key = _levelKeys[where.level.id];
        if (key != null) {
          flyEmoji(context, emoji: item.emoji, from: from, to: centerOf(key));
        }
      },
    );
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
            tooltip: s.edit,
            iconSize: 26,
            onPressed: () async {
              final r = await showEditShelfSheet(context, room, shelf);
              if (r == ShelfEditResult.deleted && context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.edit_rounded),
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
            Widget row = _LevelRow(
              key: _keyFor(level.id),
              shelf: shelf,
              level: level,
              number: shelf.levelNumber(i),
              yOffset: y,
              glow: isHi ? glow : 0,
              pulseItemId: isHi ? widget.highlightItemId : null,
              onAdd: () => _quickAdd(room, shelf, level, i),
              onLongPress: () => _levelMenu(shelf, level, i),
              onOpened: () {
                if (isHi) _faro.reset();
              },
            );
            if (_justAdded.contains(level.id)) {
              // Nuovo piano: entra di lato con un "clic".
              row = row
                  .animate(onComplete: (_) => _justAdded.remove(level.id))
                  .fadeIn(duration: Motion.of(context, 200))
                  .slideX(begin: 1.0, curve: Curves.easeOutBack, duration: Motion.of(context, 480));
            }
            if (_removing.contains(level.id)) {
              row = row
                  .animate(onComplete: (_) {
                    _removing.remove(level.id);
                    store.deleteLevel(shelf, level);
                    HapticFeedback.lightImpact();
                  })
                  .fadeOut(duration: Motion.of(context, 220))
                  .slideX(end: -1, curve: Curves.easeInCubic, duration: Motion.of(context, 280));
            }
            rows.add(KeyedSubtree(key: ValueKey(level.id), child: row));
            y += _levelHeight;
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '${room.emoji} ${room.name} · ${s.levelsCount(shelf.levels.length)} · ${s.itemsCount(shelf.itemCount)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: AnimatedSize(
                    duration: Motion.of(context, 320),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        SizedBox(height: _capHeight, width: double.infinity, child: CustomPaint(painter: ShelfCapPainter())),
                        ...rows,
                        SizedBox(
                          height: 26,
                          width: double.infinity,
                          child: CustomPaint(painter: ShelfFeetPainter(yOffset: y)),
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

class _LevelRow extends StatefulWidget {
  const _LevelRow({
    super.key,
    required this.shelf,
    required this.level,
    required this.number,
    required this.yOffset,
    required this.glow,
    required this.onAdd,
    required this.onLongPress,
    required this.onOpened,
    this.pulseItemId,
  });

  final Shelf shelf;
  final Level level;
  final int number;
  final double yOffset;
  final double glow;
  final String? pulseItemId;
  final VoidCallback onAdd;
  final VoidCallback onLongPress;
  final VoidCallback onOpened;

  @override
  State<_LevelRow> createState() => _LevelRowState();
}

class _LevelRowState extends State<_LevelRow> {
  bool _pressed = false;

  double _tiltFor(String id) => ((id.hashCode % 7) - 3) * 0.025;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final level = widget.level;
    final color = TrovoColors.level(level.colorIndex);
    final glow = widget.glow;

    final content = SizedBox(
      height: _levelHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: _pressed ? 1 : 0),
              duration: Motion.of(context, 150),
              builder: (context, p, _) => CustomPaint(
                painter: LevelFramePainter(
                  color: color,
                  yOffset: widget.yOffset,
                  highlight: glow,
                  pressed: p,
                ),
              ),
            ),
          ),
          // Oggetti in piedi sul ripiano.
          Positioned(
            left: LevelFramePainter.uprightWidth + 12,
            right: LevelFramePainter.uprightWidth + 8,
            top: 8,
            height: _levelHeight * LevelFramePainter.boardTop - 10,
            child: LayoutBuilder(
              builder: (context, c) {
                const sticker = 54.0;
                const gap = 10.0;
                final addW = 48.0 + gap;
                final fit = math.max(0, ((c.maxWidth - addW + gap) / (sticker + gap)).floor());
                final items = level.items;
                final showMore = items.length > fit;
                final shown = showMore ? math.max(0, fit - 1) : items.length;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < shown; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: gap),
                        child: Tooltip(
                          message: items[i].name,
                          child: _Pulse(
                            active: items[i].id == widget.pulseItemId,
                            glow: glow,
                            child: ItemSticker(
                              item: items[i],
                              size: sticker,
                              tilt: _tiltFor(items[i].id),
                              glow: items[i].id == widget.pulseItemId ? glow : 0,
                            ),
                          ),
                        ),
                      ),
                    if (showMore)
                      Container(
                        width: sticker,
                        height: sticker,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: TrovoColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(sticker * 0.28),
                          border: Border.all(color: TrovoColors.metalDark, width: 2),
                        ),
                        child: Text('+${items.length - shown}', style: Theme.of(context).textTheme.titleMedium),
                      ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: IconButton.filledTonal(
                        tooltip: s.add,
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          widget.onAdd();
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: color.withValues(alpha: 0.22),
                          foregroundColor: color,
                          minimumSize: const Size(48, 48),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 28),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Etichetta con numero sul bordo del ripiano.
          Positioned(
            left: LevelFramePainter.uprightWidth + 4,
            bottom: 2,
            child: LevelTag(number: widget.number, color: color, size: 34, glow: glow),
          ),
          Positioned(
            right: LevelFramePainter.uprightWidth + 8,
            bottom: 12,
            child: Text(
              s.itemsCount(level.items.length),
              style: TextStyle(
                fontFamily: TrovoTheme.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: TrovoColors.onColor(Color.lerp(color, TrovoColors.found, glow)!),
              ),
            ),
          ),
        ],
      ),
    );

    // "Cassetto": il piano si apre a schermo intero.
    return OpenContainer(
      tappable: false,
      transitionDuration: Motion.of(context, 400),
      closedColor: TrovoColors.background,
      openColor: TrovoColors.background,
      middleColor: TrovoColors.background,
      closedElevation: 0,
      openElevation: 0,
      closedShape: const RoundedRectangleBorder(),
      closedBuilder: (context, open) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onOpened();
          open();
        },
        onLongPress: widget.onLongPress,
        child: Semantics(
          button: true,
          label: '${s.level(widget.number)}, ${s.itemsCount(level.items.length)}',
          child: content,
        ),
      ),
      openBuilder: (context, _) => LevelScreen(levelId: level.id),
    );
  }
}

/// L'oggetto cercato pulsa (fa parte del "Faro").
class _Pulse extends StatelessWidget {
  const _Pulse({required this.active, required this.glow, required this.child});
  final bool active;
  final double glow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return Transform.scale(scale: 1 + 0.18 * glow, child: child);
  }
}
