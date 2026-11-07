import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models.dart';
import '../store_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';
import '../widgets/shelf_art.dart';
import '../widgets/voice_sheet.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'shelf_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openSearch(BuildContext context, {bool voice = false}) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: Motion.of(context, 320),
      reverseTransitionDuration: Motion.of(context, 260),
      pageBuilder: (_, _, _) => SearchScreen(startWithVoice: voice),
      transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
    ));
  }

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

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newShelf(context),
        icon: const Icon(Icons.add_rounded, size: 28),
        label: Text(s.newShelf),
      ).animate().scale(delay: Motion.of(context, 300), curve: Curves.easeOutBack, duration: Motion.of(context, 400)),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const _Logo(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.appName, style: theme.textTheme.headlineMedium),
                          Text(s.tagline, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: s.settings,
                      iconSize: 28,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                      icon: const Icon(Icons.settings_rounded),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: _SearchBar(
                  onTap: () => _openSearch(context),
                  onMic: () => _openSearch(context, voice: true),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _RoomBar()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '${room.emoji}  ${s.shelvesCount(room.shelves.length)} · ${s.itemsCount(room.itemCount)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
            if (room.shelves.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: EmptyState(
                    art: const _EmptyShelfArt(),
                    title: s.emptyRoomTitle,
                    body: s.emptyRoomBody,
                    action: FilledButton.icon(
                      onPressed: () => _newShelf(context),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(s.newShelf),
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
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _DraggableShelfCard(
                      key: ValueKey(room.shelves[i].id),
                      room: room,
                      index: i,
                    )
                        .animate()
                        .fadeIn(delay: Motion.of(context, 50 * i), duration: Motion.of(context, 260))
                        .slideY(begin: 0.15, curve: Curves.easeOutCubic, duration: Motion.of(context, 320)),
                    childCount: room.shelves.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: TrovoColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: CustomPaint(
        painter: MiniShelfPainter(
          levelColors: [TrovoColors.level(3), TrovoColors.level(0), TrovoColors.level(2)],
          itemCounts: const [2, 3, 1],
          highlightIndex: 1,
          glow: 1,
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap, required this.onMic});
  final VoidCallback onTap;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Hero(
      tag: 'search-bar',
      child: Material(
        color: TrovoColors.surfaceHigh,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 30, color: TrovoColors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.searchHint,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: TrovoColors.textMuted),
                  ),
                ),
                MicButton(onPressed: onMic, size: 52),
              ],
            ),
          ),
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
    final st = context.watchStore;
    final selected = st.selectedRoom;
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final room in st.rooms)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  showRoomSheet(context, room: room);
                },
                child: ChoiceChip(
                  selected: room.id == selected.id,
                  showCheckmark: false,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    st.selectRoom(room);
                  },
                  avatar: Text(room.emoji, style: const TextStyle(fontSize: 20)),
                  label: Text(room.name),
                  labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: room.id == selected.id ? TrovoColors.onPrimary : TrovoColors.text,
                      ),
                ),
              ),
            ),
          ActionChip(
            avatar: const Icon(Icons.add_rounded, size: 22),
            label: Text(s.room),
            onPressed: () => showRoomSheet(context),
          ),
        ],
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
          scale: _hovered ? 1.05 : 1,
          duration: Motion.of(context, 180),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: Motion.of(context, 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _hovered ? TrovoColors.primary : Colors.transparent, width: 2.5),
            ),
            child: LongPressDraggable<int>(
              data: widget.index,
              hapticFeedbackOnStart: true,
              feedback: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Transform.rotate(
                  angle: 0.04,
                  child: Material(
                    color: Colors.transparent,
                    elevation: 12,
                    shadowColor: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    child: _ShelfCard(room: widget.room, shelf: shelf, interactive: false),
                  ),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.25, child: card),
              child: card,
            ),
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

    Widget closed(VoidCallback? open) => Material(
          color: TrovoColors.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: open == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    open();
                  },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, c) => MiniShelf(
                          width: c.maxWidth * 0.82,
                          height: c.maxHeight,
                          levelColors: [for (final l in shelf.levels) TrovoColors.level(l.colorIndex)],
                          itemCounts: [for (final l in shelf.levels) l.items.length],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ColorDot(color: shelfColor, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shelf.name,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.levelsCount(shelf.levels.length)} · ${s.itemsCount(shelf.itemCount)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        );

    if (!interactive) return closed(null);

    // "Container transform": la scheda si allarga e diventa lo scaffale.
    return OpenContainer(
      tappable: false,
      transitionDuration: Motion.of(context, 420),
      closedColor: TrovoColors.surface,
      openColor: TrovoColors.background,
      middleColor: TrovoColors.background,
      closedElevation: 0,
      openElevation: 0,
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      closedBuilder: (context, open) => closed(open),
      openBuilder: (context, _) => ShelfScreen(shelfId: shelf.id),
    );
  }
}

class _EmptyShelfArt extends StatelessWidget {
  const _EmptyShelfArt();

  @override
  Widget build(BuildContext context) {
    return MiniShelf(
      width: 120,
      height: 140,
      levelColors: [for (var i = 0; i < 4; i++) TrovoColors.level(i).withValues(alpha: 0.5)],
      itemCounts: const [0, 0, 0, 0],
    )
        .animate()
        .fadeIn(duration: Motion.of(context, 400))
        .moveY(begin: 12, end: 0, duration: Motion.of(context, 500), curve: Curves.easeOutBack);
  }
}
