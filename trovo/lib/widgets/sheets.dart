import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../icons.dart';

import '../emoji_guess.dart';
import '../room_icons.dart';
import '../screens/scan_screen.dart';
import '../services/product_lookup.dart';
import '../models.dart';
import '../store_scope.dart';
import '../theme.dart';
import 'common.dart';
import 'glass.dart';
import 'fly.dart';
import 'shelf_art.dart';
import 'voice_sheet.dart';

Future<T?> _sheet<T>(BuildContext context, Widget child) => showGlassSheet<T>(context, builder: (_) => child);

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 6),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: TrovoColors.textMuted)),
      );
}

/// Cerchi colorati per scegliere il colore dello scaffale.
class _ShelfColorPicker extends StatelessWidget {
  const _ShelfColorPicker({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < TrovoColors.shelfColors.length; i++)
          Semantics(
            label: context.s.colorName(i),
            selected: i == value,
            button: true,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(i);
              },
              child: AnimatedContainer(
                duration: Motion.of(context, 200),
                curve: Curves.easeOutBack,
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: TrovoColors.shelf(i),
                  shape: BoxShape.circle,
                  border: Border.all(color: i == value ? Colors.white : Colors.transparent, width: 3),
                  boxShadow: i == value
                      ? [BoxShadow(color: TrovoColors.shelf(i).withValues(alpha: 0.6), blurRadius: 14)]
                      : null,
                ),
                child: i == value ? const Icon(PIcons.checkBold, color: Colors.white, size: 26) : null,
              ),
            ),
          ),
      ],
    );
  }
}

// ───────────────────────────────────────── Nuovo scaffale

Future<Shelf?> showNewShelfSheet(BuildContext context, Room room) =>
    _sheet<Shelf>(context, _NewShelfSheet(room: room));

class _NewShelfSheet extends StatefulWidget {
  const _NewShelfSheet({required this.room});
  final Room room;

  @override
  State<_NewShelfSheet> createState() => _NewShelfSheetState();
}

class _NewShelfSheetState extends State<_NewShelfSheet> {
  late int _color = context.store.nextShelfColor(widget.room);
  int _levels = 5;
  int _slots = Level.defaultSlots;
  bool _fromTop = true;
  late final TextEditingController _name = TextEditingController(text: context.s.shelfDefaultName(_color));
  bool _nameEdited = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _create() {
    final name = _name.text.trim().isEmpty ? context.s.shelfDefaultName(_color) : _name.text;
    HapticFeedback.mediumImpact();
    final shelf = context.store.addShelf(
      widget.room,
      name: name,
      colorIndex: _color,
      levelCount: _levels,
      slotsPerLevel: _slots,
      numberFromTop: _fromTop,
    );
    Navigator.pop(context, shelf);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetTitle(s.newShelf),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShelfPreview(levels: _levels, slots: _slots, fromTop: _fromTop),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label(s.howManyLevels),
                    QuantityStepper(
                      value: _levels,
                      min: 1,
                      max: 20,
                      big: true,
                      onChanged: (v) => setState(() => _levels = v),
                    ),
                    const SizedBox(height: 16),
                    _Label(s.slotsPerLevel),
                    QuantityStepper(
                      value: _slots,
                      min: 1,
                      max: 30,
                      big: true,
                      onChanged: (v) => setState(() => _slots = v),
                    ),
                    const SizedBox(height: 16),
                    _Label(s.levelOneIs),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: true, label: Text(s.atTop)),
                        ButtonSegment(value: false, label: Text(s.atBottom)),
                      ],
                      selected: {_fromTop},
                      onSelectionChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _fromTop = v.first);
                      },
                      style: SegmentedButton.styleFrom(
                        textStyle: theme.textTheme.labelMedium,
                        selectedBackgroundColor: TrovoColors.primary,
                        selectedForegroundColor: TrovoColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Label(s.color),
          _ShelfColorPicker(
            value: _color,
            onChanged: (i) => setState(() {
              _color = i;
              if (!_nameEdited) _name.text = s.shelfDefaultName(i);
            }),
          ),
          const SizedBox(height: 20),
          _Label(s.shelfName),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.bodyLarge,
            onChanged: (_) => _nameEdited = true,
            onSubmitted: (_) => _create(),
          ),
          const SizedBox(height: 24),
          PrimaryButton(onPressed: _create, icon: PIcons.checkBold, label: s.create),
        ],
      ),
    );
  }
}

/// Anteprima dello scaffale che cresce mentre premi +.
class ShelfPreview extends StatelessWidget {
  const ShelfPreview({super.key, required this.levels, required this.slots, required this.fromTop});
  final int levels;
  final int slots;
  final bool fromTop;

  @override
  Widget build(BuildContext context) {
    const rowH = 34.0;
    const width = 132.0;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: width, maxHeight: 380),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: AnimatedSize(
          duration: Motion.of(context, 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 10, width: width, child: CustomPaint(painter: ShelfCapPainter())),
                for (var i = 0; i < levels; i++)
                  _PreviewLevel(
                    key: ValueKey('lvl$i'),
                    number: fromTop ? i + 1 : levels - i,
                    slots: slots,
                    height: rowH,
                    yOffset: 10 + i * rowH,
                  ),
                SizedBox(
                  height: 16,
                  width: width,
                  child: CustomPaint(painter: ShelfFeetPainter(yOffset: 10 + levels * rowH)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewLevel extends StatelessWidget {
  const _PreviewLevel({super.key, required this.number, required this.slots, required this.height, required this.yOffset});
  final int number;
  final int slots;
  final double height;
  final double yOffset;

  @override
  Widget build(BuildContext context) {
    final color = TrovoColors.level(number - 1);
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: CustomPaint(painter: LevelFramePainter(color: color, yOffset: yOffset))),
          // I posti: quadratini vuoti con il + dentro.
          Positioned(
            left: LevelFramePainter.uprightWidth + 3,
            right: LevelFramePainter.uprightWidth + 3,
            bottom: height * 0.24,
            height: height * 0.5,
            child: Row(
              children: [
                for (var i = 0; i < slots; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.2),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: TrovoColors.metal.withValues(alpha: 0.7), width: 1),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            left: 22,
            bottom: 1,
            child: AnimatedSwitcher(
              duration: Motion.of(context, 200),
              child: LevelTag(key: ValueKey(number), number: number, color: color, size: 20),
            ),
          ),
        ],
      ),
    )
        .animate(key: key)
        .fadeIn(duration: Motion.of(context, 220))
        .slideX(begin: 0.4, curve: Curves.easeOutBack, duration: Motion.of(context, 320));
  }
}

// ───────────────────────────────────────── Modifica scaffale

enum ShelfEditResult { saved, deleted }

Future<ShelfEditResult?> showEditShelfSheet(BuildContext context, Room room, Shelf shelf) =>
    _sheet<ShelfEditResult>(context, _EditShelfSheet(room: room, shelf: shelf));

class _EditShelfSheet extends StatefulWidget {
  const _EditShelfSheet({required this.room, required this.shelf});
  final Room room;
  final Shelf shelf;

  @override
  State<_EditShelfSheet> createState() => _EditShelfSheetState();
}

class _EditShelfSheetState extends State<_EditShelfSheet> {
  late int _color = widget.shelf.colorIndex;
  late bool _fromTop = widget.shelf.numberFromTop;
  late final TextEditingController _name = TextEditingController(text: widget.shelf.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetTitle(s.edit),
          _Label(s.shelfName),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          _Label(s.color),
          _ShelfColorPicker(value: _color, onChanged: (i) => setState(() => _color = i)),
          const SizedBox(height: 20),
          _Label(s.levelOneIs),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: true, label: Text(s.atTop)),
              ButtonSegment(value: false, label: Text(s.atBottom)),
            ],
            selected: {_fromTop},
            onSelectionChanged: (v) => setState(() => _fromTop = v.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: TrovoColors.primary,
              selectedForegroundColor: TrovoColors.onPrimary,
            ),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: s.save,
            onPressed: () {
              context.store.updateShelf(widget.shelf, name: _name.text, colorIndex: _color, numberFromTop: _fromTop);
              Navigator.pop(context, ShelfEditResult.saved);
            },
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: TrovoColors.danger),
            onPressed: () async {
              final ok = await confirmDialog(context, s.deleteShelfConfirm(widget.shelf.name));
              if (!ok || !context.mounted) return;
              context.store.deleteShelf(widget.room, widget.shelf);
              Navigator.pop(context, ShelfEditResult.deleted);
            },
            icon: const Icon(PIcons.trash),
            label: Text(s.delete),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────── Stanze

Future<Room?> showRoomSheet(BuildContext context, {Room? room}) =>
    _sheet<Room>(context, _RoomSheet(room: room));

class _RoomSheet extends StatefulWidget {
  const _RoomSheet({this.room});
  final Room? room;

  @override
  State<_RoomSheet> createState() => _RoomSheetState();
}

class _RoomSheetState extends State<_RoomSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.room?.name ?? '');
  late String _icon = widget.room?.icon ?? 'house';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final store = context.store;
    HapticFeedback.mediumImpact();
    if (widget.room == null) {
      Navigator.pop(context, store.addRoom(name, _icon));
    } else {
      store.updateRoom(widget.room!, name: name, icon: _icon);
      Navigator.pop(context, widget.room);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final editing = widget.room != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetTitle(editing ? s.edit : s.newRoom),
          _Label(s.roomName),
          TextField(
            controller: _name,
            autofocus: !editing,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(hintText: s.roomNameHint),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 20),
          _Label(s.icon),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final key in roomIconKeys)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _icon = key);
                  },
                  child: AnimatedContainer(
                    duration: Motion.of(context, 180),
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: key == _icon ? TrovoColors.primary.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: key == _icon ? TrovoColors.primaryOnGlass : Colors.white.withValues(alpha: 0.10),
                        width: key == _icon ? 1.5 : 1,
                      ),
                    ),
                    child: Icon(
                      roomIcon(key),
                      size: 26,
                      color: key == _icon ? TrovoColors.primaryOnGlass : TrovoColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          PrimaryButton(onPressed: _name.text.trim().isEmpty ? null : _save, label: editing ? s.save : s.create),
          if (editing) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: TrovoColors.danger),
              onPressed: () async {
                final store = context.store;
                if (store.rooms.length <= 1) {
                  showToast(context, s.cantDeleteLastRoom);
                  return;
                }
                final ok = await confirmDialog(context, s.deleteRoomConfirm(widget.room!.name));
                if (!ok || !context.mounted) return;
                store.deleteRoom(widget.room!);
                Navigator.pop(context);
              },
              icon: const Icon(PIcons.trash),
              label: Text(s.delete),
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────────────────── Scegli il piano

Future<LevelRef?> showLevelPicker(BuildContext context, {String? currentLevelId}) => showGlassSheet<LevelRef>(
      context,
      builder: (ctx) => SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.72,
        child: _LevelPicker(controller: ScrollController(), currentLevelId: currentLevelId),
      ),
    );

class _LevelPicker extends StatelessWidget {
  const _LevelPicker({required this.controller, this.currentLevelId});
  final ScrollController controller;
  final String? currentLevelId;

  @override
  Widget build(BuildContext context) {
    final store = context.watchStore;
    final s = context.s;
    final theme = Theme.of(context);
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        _SheetTitle(s.whereDoesItGo),
        for (final room in store.rooms)
          if (room.shelves.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(children: [
                Icon(roomIcon(room.icon), size: 20, color: TrovoColors.textMuted),
                const SizedBox(width: 8),
                Text(room.name, style: theme.textTheme.titleMedium),
              ]),
            ),
            for (final shelf in room.shelves)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  radius: 20,
                  shadow: false,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        ColorDot(color: TrovoColors.shelf(shelf.colorIndex)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(shelf.name, style: theme.textTheme.titleSmall)),
                      ]),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (var li = 0; li < shelf.levels.length; li++)
                            _LevelChoice(
                              number: shelf.levelNumber(li),
                              color: TrovoColors.level(shelf.levels[li].colorIndex),
                              selected: shelf.levels[li].id == currentLevelId,
                              onTap: () => Navigator.pop(
                                context,
                                LevelRef(room: room, shelf: shelf, level: shelf.levels[li], levelIndex: li),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
      ],
    );
  }
}

class _LevelChoice extends StatelessWidget {
  const _LevelChoice({required this.number, required this.color, required this.selected, required this.onTap});
  final int number;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 2.5),
        ),
        child: LevelTag(number: number, color: color, size: 46),
      ),
    );
  }
}

// ───────────────────────────────────────── Emoji

Future<String?> showEmojiPicker(BuildContext context, String current) => showGlassSheet<String>(
      context,
      builder: (ctx) => SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.6,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetTitle(ctx.s.chooseIcon),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 64,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: pickableEmojis.length,
                  itemBuilder: (_, i) {
                    final e = pickableEmojis[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(ctx, e),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: e == current ? TrovoColors.primary.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: e == current ? TrovoColors.primaryOnGlass : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 30)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

// ───────────────────────────────────────── Aggiungi oggetto

typedef ItemAdded = void Function(Item item, LevelRef where, Offset from);

Future<void> showAddItemSheet(
  BuildContext context, {
  LevelRef? target,
  int? position,
  String initialName = '',
  String? barcode,
  ItemAdded? onAdded,
}) =>
    _sheet<void>(
      context,
      _AddItemSheet(
        target: target,
        position: position,
        initialName: initialName,
        barcode: barcode,
        onAdded: onAdded,
      ),
    );

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet({this.target, this.position, this.initialName = '', this.barcode, this.onAdded});
  final LevelRef? target;

  /// Posto scelto (da 0). Se null: il primo libero.
  final int? position;
  final String initialName;
  final String? barcode;
  final ItemAdded? onAdded;

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.initialName);
  final _focus = FocusNode();
  final _addKey = GlobalKey();
  late LevelRef? _target = widget.target;
  late int? _position = widget.position;
  late String? _barcode = widget.barcode;
  bool _looking = false;
  int _qty = 1;
  String? _manualEmoji;
  String? _lastAdded;
  int _addedCount = 0;

  String get _emoji => _manualEmoji ?? guessEmoji(_name.text);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.target != null) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _pickLevel() async {
    final ref = await showLevelPicker(context, currentLevelId: _target?.level.id);
    if (ref != null && mounted) {
      setState(() {
        _target = ref;
        _position = null;
      });
      _focus.requestFocus();
    }
  }

  /// Codice a barre: il nome si scrive da solo (Open Food Facts).
  Future<void> _scanBarcode() async {
    final code = await scanBarcode(context);
    if (code == null || !mounted) return;
    final s = context.s;
    final existing = context.store.findByBarcode(code);
    setState(() {
      _barcode = code;
      _looking = true;
    });
    final name = existing?.name ?? await lookupProductName(code, italian: s.it);
    if (!mounted) return;
    setState(() {
      _looking = false;
      if (name != null) {
        _name.text = name;
        _manualEmoji = existing?.emoji;
      }
    });
    if (name == null) showToast(context, s.productNotFound);
    _focus.requestFocus();
  }

  Future<void> _dictate() async {
    final words = await listenForWords(context);
    if (words == null || !mounted) return;
    final text = words[0].toUpperCase() + words.substring(1);
    setState(() => _name.text = text);
    _name.selection = TextSelection.collapsed(offset: text.length);
  }

  void _add() {
    final name = _name.text.trim();
    final target = _target;
    if (name.isEmpty) {
      _focus.requestFocus();
      return;
    }
    if (target == null) {
      _pickLevel();
      return;
    }
    final store = context.store;
    final item = Item(
      name: name[0].toUpperCase() + name.substring(1),
      emoji: _emoji,
      quantity: _qty,
      barcode: _barcode,
    );
    final placed = store.addItem(target.level, item, position: _position);
    // A raffica: la cosa successiva va nel primo posto libero più a destra.
    final slots = target.level.slots;
    var next = -1;
    for (var i = placed + 1; i < slots.length; i++) {
      if (slots[i] == null) {
        next = i;
        break;
      }
    }
    _position = next >= 0 ? next : null;
    HapticFeedback.mediumImpact();
    final from = centerOf(_addKey);
    widget.onAdded?.call(item, target, from);
    if (store.keepAdding) {
      setState(() {
        _lastAdded = '${item.emoji} ${context.s.added(item.name)}';
        _addedCount++;
        _name.clear();
        _qty = 1;
        _manualEmoji = null;
        _barcode = null;
      });
      _focus.requestFocus();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final store = context.watchStore;
    final target = _target;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetTitle(s.whatDoYouPut),
          // Dove va: già compilato, si può cambiare.
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _pickLevel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: TrovoColors.surfaceHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: target == null ? TrovoColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: target == null
                        ? Text(s.whereDoesItGo, style: theme.textTheme.titleSmall?.copyWith(color: TrovoColors.primary))
                        : LocationLine(
                            room: target.room,
                            shelf: target.shelf,
                            levelIndex: target.levelIndex,
                            position: (_position ?? target.level.slots.indexOf(null)) + 1,
                          ),
                  ),
                  const Icon(PIcons.mapPin, color: TrovoColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Emoji indovinata dal nome: tocca per cambiarla.
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  final e = await showEmojiPicker(context, _emoji);
                  if (e != null) setState(() => _manualEmoji = e);
                },
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                  ),
                  child: AnimatedSwitcher(
                    duration: Motion.of(context, 220),
                    transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
                    child: Text(_emoji, key: ValueKey(_emoji), style: const TextStyle(fontSize: 34)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _name,
                  focusNode: _focus,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  style: theme.textTheme.titleMedium,
                  decoration: InputDecoration(hintText: s.itemNameHint),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 10),
              MicButton(onPressed: _dictate, size: 56, tooltip: s.dictate),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _looking ? null : _scanBarcode,
            icon: _looking
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Icon(PIcons.barcode),
            label: Text(_looking ? s.lookingUp : (_barcode == null ? s.scanBarcode : '${s.scanBarcode} ✓')),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(s.quantity, style: theme.textTheme.titleSmall),
              const Spacer(),
              QuantityStepper(value: _qty, onChanged: (v) => setState(() => _qty = v)),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: store.keepAdding,
            onChanged: (v) => store.setKeepAdding(v),
            title: Text(s.keepAdding),
            subtitle: Text(s.keepAddingSub),
          ),
          AnimatedSwitcher(
            duration: Motion.of(context, 250),
            child: _lastAdded == null
                ? const SizedBox.shrink()
                : Padding(
                    key: ValueKey(_addedCount),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _lastAdded!,
                      style: theme.textTheme.titleSmall?.copyWith(color: TrovoColors.primary),
                    ).animate().fadeIn().slideY(begin: 0.4, curve: Curves.easeOutBack),
                  ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            key: _addKey,
            onPressed: _name.text.trim().isEmpty ? null : _add,
            icon: PIcons.plusBold,
            label: s.add,
          ),
          if (store.keepAdding && _addedCount > 0) ...[
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(s.done)),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────────────────── Modifica oggetto

enum ItemEditResult { saved, moved, usedUp }

Future<ItemEditResult?> showEditItemSheet(BuildContext context, ItemLocation loc) =>
    _sheet<ItemEditResult>(context, _EditItemSheet(loc: loc));

class _EditItemSheet extends StatefulWidget {
  const _EditItemSheet({required this.loc});
  final ItemLocation loc;

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.loc.item.name);
  late final TextEditingController _note = TextEditingController(text: widget.loc.item.note);
  late int _qty = widget.loc.item.quantity;
  late int _span = widget.loc.level.spanOf(widget.loc.item.id).clamp(1, 999);
  late String _emoji = widget.loc.item.emoji;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final store = context.store;
    store.updateItem(widget.loc.item, name: _name.text, emoji: _emoji, quantity: _qty, note: _note.text);
    if (_span != widget.loc.level.spanOf(widget.loc.item.id)) {
      if (!store.setSpan(widget.loc.level, widget.loc.item, _span)) {
        showToast(context, context.s.noRoomBeside);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final loc = widget.loc;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetTitle(s.editItem),
          LocationLine(room: loc.room, shelf: loc.shelf, levelIndex: loc.levelIndex, position: loc.positionNumber),
          const SizedBox(height: 16),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  final e = await showEmojiPicker(context, _emoji);
                  if (e != null) setState(() => _emoji = e);
                },
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                  ),
                  child: Text(_emoji, style: const TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(s.quantity, style: theme.textTheme.titleSmall),
              const Spacer(),
              QuantityStepper(value: _qty, onChanged: (v) => setState(() => _qty = v)),
            ],
          ),
          const SizedBox(height: 14),
          // Una cosa grande o tante confezioni possono prendere più posti.
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.span, style: theme.textTheme.titleSmall),
                    Text(s.spanSub, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              QuantityStepper(value: _span, min: 1, max: 30, onChanged: (v) => setState(() => _span = v)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(hintText: s.note),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: s.save,
            onPressed: () {
              _save();
              Navigator.pop(context, ItemEditResult.saved);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ref = await showLevelPicker(context, currentLevelId: loc.level.id);
                    if (ref == null || !context.mounted) return;
                    _save();
                    context.store.moveItem(loc.item, loc.level, ref.level);
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context, ItemEditResult.moved);
                  },
                  icon: const Icon(PIcons.arrowsOutCardinal),
                  label: Text(s.moveTo),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TrovoColors.danger,
                    side: const BorderSide(color: TrovoColors.danger, width: 1.5),
                  ),
                  onPressed: () => Navigator.pop(context, ItemEditResult.usedUp),
                  icon: const Icon(PIcons.checkCircle),
                  label: Text(s.usedUp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
