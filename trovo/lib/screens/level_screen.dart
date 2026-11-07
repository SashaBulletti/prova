import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../services/photos.dart';
import '../store_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/fly.dart';
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
    final index = store.removeItem(level, item);
    HapticFeedback.mediumImpact();
    showToast(
      context,
      '${item.emoji} ${s.removed(item.name)}',
      actionLabel: s.undo,
      onAction: () => store.insertItem(level, item, index),
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
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, size: 30),
                title: Text(s.takePhoto),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, size: 30),
                title: Text(s.fromGallery),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (level.photoPath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, size: 30, color: TrovoColors.danger),
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

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: _fabKey,
        onPressed: () => _add(ref),
        icon: const Icon(Icons.add_rounded, size: 28),
        label: Text(s.add),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: TrovoColors.background,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 14, end: 16),
              title: Text(s.level(ref.levelNumber), style: theme.textTheme.titleLarge),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color.withValues(alpha: 0.38), TrovoColors.background],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 56),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'level-tag-${level.id}',
                          child: LevelTag(number: ref.levelNumber, color: color, size: 72),
                        ).animate().scale(
                              begin: const Offset(0.6, 0.6),
                              curve: Curves.easeOutBack,
                              duration: Motion.of(context, 420),
                            ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                ColorDot(color: TrovoColors.shelf(ref.shelf.colorIndex), size: 14),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(ref.shelf.name,
                                      style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                                ),
                              ]),
                              const SizedBox(height: 4),
                              Text('${ref.room.emoji} ${ref.room.name} · ${s.itemsCount(level.items.length)}',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                art: Text('📭', style: const TextStyle(fontSize: 64))
                    .animate()
                    .scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOutBack, duration: Motion.of(context, 500)),
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
                    emojiKey: _emojiKey(item.id),
                    onTap: () => _edit(ref, item),
                    onUsedUp: () => _usedUp(level, item),
                    onQuantity: (q) => store.updateItem(item, quantity: q),
                  );
                  if (_justAdded.contains(item.id)) {
                    row = row
                        .animate(onComplete: (_) => _justAdded.remove(item.id))
                        .fadeIn(delay: Motion.of(context, 380), duration: Motion.of(context, 200))
                        .scale(
                          begin: const Offset(0.85, 0.85),
                          delay: Motion.of(context, 380),
                          curve: Curves.elasticOut,
                          duration: Motion.of(context, 700),
                        );
                  } else {
                    row = row
                        .animate()
                        .fadeIn(delay: Motion.of(context, 30 * i.clamp(0, 10)), duration: Motion.of(context, 220))
                        .slideX(begin: 0.08, curve: Curves.easeOutCubic, duration: Motion.of(context, 280));
                  }
                  return KeyedSubtree(key: ValueKey('row-${item.id}'), child: row);
                },
              ),
            ),
        ],
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
      return Material(
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        color: TrovoColors.surface,
        child: InkWell(
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
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_camera_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Material(
      color: TrovoColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: TrovoColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add_a_photo_rounded, size: 28, color: TrovoColors.textMuted),
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
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    super.key,
    required this.item,
    required this.emojiKey,
    required this.onTap,
    required this.onUsedUp,
    required this.onQuantity,
  });

  final Item item;
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
      child: Material(
        color: TrovoColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  key: emojiKey,
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: TrovoColors.surfaceHigher,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                  ),
                  child: Text(item.emoji, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (item.note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(item.note, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                ),
                QuantityStepper(value: item.quantity, onChanged: onQuantity),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _swipeBg(String label, Alignment align) => Container(
        alignment: align,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: TrovoColors.primary.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: TrovoColors.primary, size: 28),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontFamily: TrovoTheme.fontFamily, fontWeight: FontWeight.w700, fontSize: 18, color: TrovoColors.primary)),
          ],
        ),
      );
}
