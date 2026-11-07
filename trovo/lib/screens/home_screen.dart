import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../icons.dart';

import '../models.dart';
import '../room_icons.dart';
import '../store_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/sheets.dart';
import '../widgets/shelf_art.dart';
import 'settings_screen.dart';
import 'shelf_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onSearch, required this.onVoice});

  final VoidCallback onSearch;
  final VoidCallback onVoice;

  Future<void> _newShelf(BuildContext context) async {
    final store = context.store;
    final shelf = await showNewShelfSheet(context, store.selectedRoom);
    if (shelf != null && context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShelfScreen(shelfId: shelf.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watchStore;
    final s = context.s;
    final theme = Theme.of(context);
    final room = store.selectedRoom;
    final totalItems = store.rooms.fold<int>(0, (sum, r) => sum + r.itemCount);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          // Titolo grande stile iOS.
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.appName, style: theme.textTheme.displaySmall),
                        const SizedBox(height: 2),
                        Text(
                          '${s.roomsCount(store.rooms.length)} · ${s.itemsCount(totalItems)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  GlassIconButton(
                    icon: PIcons.gearSix,
                    tooltip: s.settings,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
            sliver: SliverToBoxAdapter(child: _SearchCapsule(onTap: onSearch, onMic: onVoice)),
          ),
          const SliverToBoxAdapter(child: _RoomBar()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Icon(roomIcon(room.icon), size: 20, color: TrovoColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(child: Text(room.name, style: theme.textTheme.titleMedium)),
                  Text(
                    '${s.shelvesCount(room.shelves.length)} · ${s.itemsCount(room.itemCount)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          if (room.shelves.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Center(
                  child: EmptyState(
                    icon: PIcons.lockers,
                    title: s.emptyRoomTitle,
                    body: s.emptyRoomBody,
                    action: SizedBox(
                      width: 240,
                      child: PrimaryButton(
                        label: s.newShelf,
                        icon: PIcons.plusBold,
                        onPressed: () => _newShelf(context),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.74,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final Widget card = i < room.shelves.length
                        ? _DraggableShelfCard(key: ValueKey(room.shelves[i].id), room: room, index: i)
                        : _AddCard(label: s.newShelf, onTap: () => _newShelf(context));
                    return card
                        .animate()
                        .fadeIn(delay: Motion.of(context, 30 * i.clamp(0, 6)), duration: Motion.of(context, 180))
                        .moveY(begin: 10, end: 0, curve: Motion.standard, duration: Motion.of(context, 350));
                  },
                  childCount: room.shelves.length + 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchCapsule extends StatelessWidget {
  const _SearchCapsule({required this.onTap, required this.onMic});
  final VoidCallback onTap;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SizedBox(
      height: 52,
      child: GlassCard(
        radius: 26,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(18, 0, 8, 0),
        child: Row(
          children: [
            Icon(PIcons.magnifyingGlass, size: 22, color: TrovoColors.text.withValues(alpha: 0.6)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                s.searchHint,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TrovoColors.textMuted),
              ),
            ),
            Semantics(
              button: true,
              label: s.searchByVoice,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onMic();
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: TrovoColors.primary.withValues(alpha: 0.18),
                  ),
                  child: const Icon(PIcons.microphoneFill, size: 20, color: TrovoColors.primaryOnGlass),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomBar extends StatelessWidget {
  const _RoomBar();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final store = context.watchStore;
    final selected = store.selectedRoom;
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          for (final room in store.rooms)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _RoomChip(
                icon: roomIcon(room.icon),
                label: room.name,
                count: room.itemCount,
                selected: room.id == selected.id,
                onTap: () => store.selectRoom(room),
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  showRoomSheet(context, room: room);
                },
              ),
            ),
          _RoomChip(
            icon: PIcons.plus,
            label: s.room,
            selected: false,
            onTap: () => showRoomSheet(context),
          ),
        ],
      ),
    );
  }
}

class _RoomChip extends StatelessWidget {
  const _RoomChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.onLongPress,
  });

  final IconData icon;
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Motion.of(context, 220),
      curve: Motion.snappy,
      height: 40,
      child: GlassCard(
        radius: 20,
        shadow: false,
        tint: selected ? TrovoColors.primary : null,
        tintAlpha: 0.20,
        borderColor: selected ? TrovoColors.primaryOnGlass.withValues(alpha: 0.7) : null,
        onTap: onTap,
        onLongPress: onLongPress,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? TrovoColors.primaryOnGlass : TrovoColors.textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: TrovoTheme.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? TrovoColors.text : TrovoColors.textMuted,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: TrovoTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: selected ? TrovoColors.primaryOnGlass : TrovoColors.textFaint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Scheda dello scaffale. Tieni premuto per spostarla (effetto "calamita").
class _DraggableShelfCard extends StatefulWidget {
  const _DraggableShelfCard({super.key, required this.room, required this.index});
  final Room room;
  final int index;

  @override
  State<_DraggableShelfCard> createState() => _DraggableShelfCardState();
}

class _DraggableShelfCardState extends State<_DraggableShelfCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final shelf = widget.room.shelves[widget.index];
    final card = _ShelfCard(room: widget.room, shelf: shelf);
    return LayoutBuilder(
      builder: (context, constraints) => DragTarget<int>(
        onWillAcceptWithDetails: (d) {
          final accept = d.data != widget.index;
          if (accept) {
            HapticFeedback.selectionClick();
            setState(() => _hovered = true);
          }
          return accept;
        },
        onLeave: (_) => setState(() => _hovered = false),
        onAcceptWithDetails: (d) {
          setState(() => _hovered = false);
          HapticFeedback.mediumImpact();
          context.store.moveShelf(widget.room, d.data, widget.index);
        },
        builder: (context, candidates, _) => AnimatedScale(
          scale: _hovered ? 1.04 : 1,
          duration: Motion.of(context, 220),
          curve: Motion.snappy,
          child: LongPressDraggable<int>(
            data: widget.index,
            hapticFeedbackOnStart: true,
            feedback: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Transform.rotate(
                angle: 0.03,
                child: Material(
                  type: MaterialType.transparency,
                  child: _ShelfCard(room: widget.room, shelf: shelf, interactive: false),
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.25, child: card),
            child: card,
          ),
        ),
      ),
    );
  }
}

class _ShelfCard extends StatelessWidget {
  const _ShelfCard({required this.room, required this.shelf, this.interactive = true});
  final Room room;
  final Shelf shelf;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final shelfColor = TrovoColors.shelf(shelf.colorIndex);

    Widget closed(VoidCallback? open) => GlassCard(
          radius: 24,
          onTap: open,
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, c) => MiniShelf(
                      width: c.maxWidth * 0.78,
                      height: c.maxHeight,
                      levelColors: [for (final l in shelf.levels) TrovoColors.level(l.colorIndex)],
                      slots: shelfSlots(shelf.levels.map((l) => l.slots)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ColorDot(color: shelfColor, size: 9),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(shelf.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${s.levelsCount(shelf.levels.length)} · ${s.itemsCount(shelf.itemCount)}',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
              ),
            ],
          ),
        );

    if (!interactive) return closed(null);

    // "Container transform": la scheda si allarga e diventa lo scaffale.
    return OpenContainer(
      tappable: false,
      transitionDuration: Motion.of(context, 420),
      closedColor: Colors.transparent,
      openColor: TrovoColors.background,
      middleColor: TrovoColors.background,
      closedElevation: 0,
      openElevation: 0,
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      closedBuilder: (context, open) => closed(open),
      openBuilder: (context, _) => ShelfScreen(shelfId: shelf.id),
    );
  }
}

/// Ultima scheda della griglia: aggiungi un mobile.
class _AddCard extends StatelessWidget {
  const _AddCard({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 24,
      shadow: false,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TrovoColors.primary.withValues(alpha: 0.16),
            ),
            child: const Icon(PIcons.plus, color: TrovoColors.primaryOnGlass, size: 26),
          ),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: TrovoColors.textMuted)),
        ],
      ),
    );
  }
}
