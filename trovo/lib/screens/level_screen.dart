import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../icons.dart';

import '../models.dart';
import '../room_icons.dart';
import '../services/photos.dart';
import '../store_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/fly.dart';
import '../widgets/glass.dart';
import '../widgets/sheets.dart';

/// Un piano aperto: foto, oggetti grandi e leggibili, + per aggiungere.
class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key, required this.levelId});
  final String levelId;

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  final _fabKey = GlobalKey();
  final Map<String, GlobalKey> _emojiKeys = {};
  final Set<String> _justAdded = {};

  GlobalKey _emojiKey(String id) => _emojiKeys.putIfAbsent(id, GlobalKey.new);

  void _add(LevelRef ref) {
    showAddItemSheet(
      context,
      target: ref,
      onAdded: (item, where, from) {
        if (where.level.id != ref.level.id) {
          showToast(context, context.s.added(item.name));
          return;
        }
        setState(() => _justAdded.add(item.id));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final key = _emojiKeys[item.id];
          if (key != null && mounted) {
            flyEmoji(context, emoji: item.emoji, from: from, to: centerOf(key));
          }
        });
      },
    );
  }

  void _usedUp(Level level, Item item) {
    final store = context.store;
    final s = context.s;
    final positions = store.removeItem(level, item);
    HapticFeedback.mediumImpact();
    showToast(
      context,
      '${item.emoji} ${s.removed(item.name)}',
      actionLabel: s.undo,
      onAction: () => store.restoreItem(level, item, positions),
    );
  }

  Future<void> _edit(LevelRef ref, Item item) async {
    final loc = ItemLocation(room: ref.room, shelf: ref.shelf, level: ref.level, levelIndex: ref.levelIndex, item: item);
    final result = await showEditItemSheet(context, loc);
    if (!mounted) return;
    if (result == ItemEditResult.usedUp) _usedUp(ref.level, item);
    if (result == ItemEditResult.moved) showToast(context, context.s.moved(item.name));
  }

  Future<void> _photo(Level level) async {
    final s = context.s;
    final source = await showGlassSheet<ImageSource?>(
      context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(PIcons.camera, size: 28),
                title: Text(s.takePhoto),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(PIcons.images, size: 28),
                title: Text(s.fromGallery),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (level.photoPath != null)
                ListTile(
                  leading: const Icon(PIcons.trash, size: 28, color: TrovoColors.danger),
                  title: Text(s.removePhoto, style: const TextStyle(color: TrovoColors.danger)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final old = level.photoPath;
                    context.store.setLevelPhoto(level, null);
                    if (old != null) await deletePhoto(old);
                  },
                ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 82);
      if (file == null || !mounted) return;
      final saved = await persistPhoto(file, level.id);
      final old = level.photoPath;
      if (!mounted) return;
      context.store.setLevelPhoto(level, saved);
      if (old != null && old != saved) await deletePhoto(old);
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Trovo: foto non riuscita ($e)');
    }
  }

  Future<void> _deleteLevel(LevelRef ref) async {
    final s = context.s;
    final ok = await confirmDialog(context, s.deleteLevelConfirm(ref.levelNumber, ref.level.items.length));
    if (!ok || !mounted) return;
    Navigator.of(context).pop();
    context.store.deleteLevel(ref.shelf, ref.level);
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
      return const AuroraBackground(child: Scaffold());
    }
    final level = ref.level;
    final color = TrovoColors.level(level.colorIndex);

    return AuroraBackground(
      tint: color,
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SizedBox(
          key: _fabKey,
          width: 220,
          child: PrimaryButton(label: s.add, icon: PIcons.plusBold, onPressed: () => _add(ref)),
        ),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 196,
              backgroundColor: Colors.transparent,
              leadingWidth: 64,
              leading: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Center(
                  child: GlassIconButton(
                    icon: PIcons.arrowLeft,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              actions: [
                GlassIconButton(
                  icon: PIcons.trash,
                  tooltip: s.deleteLevel,
                  color: TrovoColors.danger,
                  onPressed: () => _deleteLevel(ref),
                ),
                const SizedBox(width: 12),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 14),
                title: Text(s.level(ref.levelNumber), style: theme.textTheme.titleSmall),
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 64, 24, 48),
                    child: Row(
                      children: [
                        LevelTag(number: ref.levelNumber, color: color, size: 64).animate().scale(
                              begin: const Offset(0.7, 0.7),
                              curve: Motion.confirm,
                              duration: Motion.of(context, 420),
                            ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                ColorDot(color: TrovoColors.shelf(ref.shelf.colorIndex), size: 9),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(ref.shelf.name, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                                ),
                              ]),
                              const SizedBox(height: 4),
                              Row(children: [
                                Icon(roomIcon(ref.room.icon), size: 16, color: TrovoColors.textMuted),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '${ref.room.name} · ${s.itemsCount(level.items.length)}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverToBoxAdapter(child: _PhotoCard(level: level, onTap: () => _photo(level))),
            ),
            if (level.items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: PIcons.package,
                  title: s.emptyLevelTitle,
                  body: s.emptyLevelBody,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                sliver: SliverList.separated(
                  itemCount: level.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = level.items[i];
                    Widget row = _ItemRow(
                      key: ValueKey(item.id),
                      item: item,
                      tint: color,
                      position: level.positionOf(item.id) + 1,
                      emojiKey: _emojiKey(item.id),
                      onTap: () => _edit(ref, item),
                      onUsedUp: () => _usedUp(level, item),
                      onQuantity: (q) => store.updateItem(item, quantity: q),
                    );
                    if (_justAdded.contains(item.id)) {
                      row = row
                          .animate(onComplete: (_) => _justAdded.remove(item.id))
                          .fadeIn(delay: Motion.of(context, 380), duration: Motion.of(context, 180))
                          .scale(
                            begin: const Offset(0.9, 0.9),
                            delay: Motion.of(context, 380),
                            curve: Motion.confirm,
                            duration: Motion.of(context, 420),
                          );
                    } else {
                      row = row
                          .animate()
                          .fadeIn(delay: Motion.of(context, 30 * i.clamp(0, 6)), duration: Motion.of(context, 180))
                          .moveY(begin: 8, end: 0, curve: Motion.standard, duration: Motion.of(context, 300));
                    }
                    return KeyedSubtree(key: ValueKey('row-${item.id}'), child: row);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.level, required this.onTap});
  final Level level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final path = level.photoPath;
    if (path != null) {
      return GlassCard(
        radius: 22,
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              photoImage(path),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle),
                  child: const Icon(PIcons.camera, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return GlassCard(
      radius: 22,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(PIcons.cameraPlus, size: 26, color: TrovoColors.textMuted),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.levelPhoto, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(s.levelPhotoHint, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    super.key,
    required this.item,
    required this.tint,
    required this.position,
    required this.emojiKey,
    required this.onTap,
    required this.onUsedUp,
    required this.onQuantity,
  });

  final Item item;
  final Color tint;
  final int position;
  final GlobalKey emojiKey;
  final VoidCallback onTap;
  final VoidCallback onUsedUp;
  final ValueChanged<int> onQuantity;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey('dismiss-${item.id}'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => onUsedUp(),
      background: _swipeBg(s.usedUp, Alignment.centerLeft),
      secondaryBackground: _swipeBg(s.usedUp, Alignment.centerRight),
      child: GlassCard(
        radius: 22,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Row(
          children: [
            KeyedSubtree(key: emojiKey, child: GlassTile(size: 56, emoji: item.emoji, tint: tint)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    item.note.isEmpty ? s.slot(position) : '${s.slot(position)} · ${item.note}',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            QuantityStepper(value: item.quantity, onChanged: onQuantity),
          ],
        ),
      ),
    );
  }

  Widget _swipeBg(String label, Alignment align) => Container(
        alignment: align,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: TrovoColors.primary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(PIcons.checkCircleFill, color: TrovoColors.primaryOnGlass, size: 26),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: TrovoTheme.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: TrovoColors.primaryOnGlass,
              ),
            ),
          ],
        ),
      );
}
