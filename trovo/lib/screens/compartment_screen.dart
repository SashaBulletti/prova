import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models.dart';
import '../store_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/labels_sheet.dart';
import '../widgets/sheets.dart';
import '../widgets/shelf3d.dart' show DragPayload;

/// Un cassetto (o un cubo) aperto, visto dall'alto: un vassoio con i posti.
/// Tocca un posto vuoto per metterci qualcosa, tieni premuto per spostare.
class CompartmentScreen extends StatefulWidget {
  const CompartmentScreen({super.key, required this.levelId, this.highlightItemId});
  final String levelId;
  final String? highlightItemId;

  @override
  State<CompartmentScreen> createState() => _CompartmentScreenState();
}

class _CompartmentScreenState extends State<CompartmentScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _faro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  int? _hover;
  bool _hoverOk = true;

  @override
  void initState() {
    super.initState();
    if (widget.highlightItemId != null) _faro.forward();
  }

  @override
  void dispose() {
    _faro.dispose();
    super.dispose();
  }

  double get _glow {
    if (widget.highlightItemId == null || _faro.status == AnimationStatus.dismissed) return 0;
    if (Motion.reduced(context)) return 1;
    return 0.3 + 0.7 * math.cos(_faro.value * 3 * math.pi).abs();
  }

  Future<void> _edit(LevelRef ref, Item item) async {
    final loc = ItemLocation(room: ref.room, shelf: ref.shelf, level: ref.level, levelIndex: ref.levelIndex, item: item);
    final result = await showEditItemSheet(context, loc);
    if (!mounted) return;
    final s = context.s;
    if (result == ItemEditResult.usedUp) {
      final store = context.store;
      final positions = store.removeItem(ref.level, item);
      HapticFeedback.mediumImpact();
      showToast(context, '${item.emoji} ${s.removed(item.name)}',
          actionLabel: s.undo, onAction: () => store.restoreItem(ref.level, item, positions));
    } else if (result == ItemEditResult.moved) {
      showToast(context, s.moved(item.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watchStore;
    final s = context.s;
    final theme = Theme.of(context);
    final ref = store.findLevel(widget.levelId);
    if (ref == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold();
    }
    final level = ref.level;
    final color = TrovoColors.level(level.colorIndex);
    final cols = math.max(2, math.min(level.columns, 6));

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: s.labels,
            iconSize: 26,
            onPressed: () => showLabelsSheet(context, shelf: ref.shelf, level: level),
            icon: const Icon(Icons.qr_code_2_rounded),
          ),
          const SizedBox(width: 4),
        ],
        titleSpacing: 0,
        title: Row(
          children: [
            LevelTag(number: ref.levelNumber, color: color, size: 30),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.compartment(level.kind, ref.levelNumber), style: theme.textTheme.titleMedium),
                  Text(ref.shelf.name, style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddItemSheet(context, target: ref),
        icon: const Icon(Icons.add_rounded, size: 28),
        label: Text(s.add),
      ),
      body: AnimatedBuilder(
        animation: _faro,
        builder: (context, _) {
          final glow = _glow;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              Text('👆 ${s.dragToMove}', style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              // Il vassoio del cassetto, visto dall'alto.
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Color.lerp(TrovoColors.surface, color, 0.06),
                  border: Border.all(color: color.withValues(alpha: 0.6), width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 8)),
                  ],
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: level.slotCount + 1,
                  itemBuilder: (context, pos) {
                    if (pos == level.slotCount) {
                      // + : un posto in più nel cassetto.
                      return _AddSlotCell(color: color, label: s.addSlot, onTap: () => store.addSlot(level));
                    }
                    final item = level.itemAt(pos);
                    final hovering = _hover == pos;
                    final Widget cell = item == null
                        ? _EmptyCell(
                            number: pos + 1,
                            onTap: () => showAddItemSheet(context, target: ref, position: pos),
                            onLongPress: () async {
                              final ok = await confirmDialog(context, s.removeSlotConfirm(pos + 1), confirmLabel: s.remove);
                              if (ok) store.removeSlot(level, pos);
                            },
                          )
                        : _ItemCell(
                            item: item,
                            level: level,
                            color: color,
                            glow: item.id == widget.highlightItemId ? glow : 0,
                            onTap: () => _edit(ref, item),
                          );
                    return DragTarget<DragPayload>(
                      onWillAcceptWithDetails: (d) {
                        final ok = store.moveItemTo(d.data.item, d.data.level, level, pos, dryRun: true);
                        if (_hover != pos) HapticFeedback.selectionClick();
                        setState(() {
                          _hover = pos;
                          _hoverOk = ok;
                        });
                        return true;
                      },
                      onLeave: (_) => setState(() => _hover = null),
                      onAcceptWithDetails: (d) {
                        final ok = store.moveItemTo(d.data.item, d.data.level, level, pos);
                        setState(() => _hover = null);
                        if (ok) {
                          HapticFeedback.mediumImpact();
                        } else {
                          HapticFeedback.heavyImpact();
                          showToast(context, s.noRoomHere);
                        }
                      },
                      builder: (context, _, _) => AnimatedContainer(
                        duration: Motion.of(context, 150),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: hovering ? (_hoverOk ? TrovoColors.primary : TrovoColors.danger).withValues(alpha: 0.3) : null,
                        ),
                        child: cell,
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(duration: Motion.of(context, 200)).moveY(begin: 20, end: 0, curve: Curves.easeOutCubic),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell({required this.number, required this.onTap, required this.onLongPress});
  final int number;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        onLongPress: onLongPress,
        child: Stack(
          children: [
            const Center(child: Icon(Icons.add_rounded, color: TrovoColors.metal, size: 30)),
            Positioned(
              left: 8,
              top: 6,
              child: Text('$number', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: TrovoColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCell extends StatelessWidget {
  const _ItemCell({required this.item, required this.level, required this.color, required this.glow, required this.onTap});
  final Item item;
  final Level level;
  final Color color;
  final double glow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: Color.lerp(TrovoColors.surfaceHigh, color, 0.14),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: glow > 0 ? TrovoColors.found.withValues(alpha: glow) : Colors.white.withValues(alpha: 0.12),
              width: glow > 0 ? 2.5 : 1,
            ),
            boxShadow: glow > 0 ? [BoxShadow(color: TrovoColors.found.withValues(alpha: 0.6 * glow), blurRadius: 18 * glow)] : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(child: ItemSticker(item: item, size: 54)),
              ),
              const SizedBox(height: 4),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
    return LongPressDraggable<DragPayload>(
      data: DragPayload(item: item, level: level, grab: 0, span: math.max(1, level.spanOf(item.id))),
      hapticFeedbackOnStart: true,
      feedback: Material(
        type: MaterialType.transparency,
        child: Transform.scale(scale: 1.1, child: ItemSticker(item: item, size: 64)),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: card,
    );
  }
}

class _AddSlotCell extends StatelessWidget {
  const _AddSlotCell({required this.color, required this.label, required this.onTap});
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          child: Center(child: Icon(Icons.add_box_outlined, color: color, size: 30)),
        ),
      ),
    );
  }
}
