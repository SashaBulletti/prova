import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store_scope.dart';
import '../theme.dart';
import 'pantry_art.dart';

/// Etichetta del piano: colore + numero grande (mai solo il colore,
/// così funziona anche per chi è daltonico).
class LevelTag extends StatelessWidget {
  const LevelTag({super.key, required this.number, required this.color, this.size = 36, this.glow = 0});

  final int number;
  final Color color;
  final double size;
  final double glow;

  @override
  Widget build(BuildContext context) {
    // Cartellino di carta colorata, con il numero a china.
    final bg = Color.lerp(color, TrovoColors.found, glow)!;
    return Container(
      constraints: BoxConstraints(minWidth: size * 1.1),
      height: size,
      padding: EdgeInsets.symmetric(horizontal: size * 0.2),
      decoration: BoxDecoration(
        color: Color.lerp(bg, Colors.white, 0.15),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: PaperColors.ink.withValues(alpha: 0.85), width: size > 26 ? 1.6 : 1.2),
        boxShadow: [
          BoxShadow(color: PaperColors.ink.withValues(alpha: 0.18), offset: const Offset(0, 2)),
          if (glow > 0) BoxShadow(color: TrovoColors.found.withValues(alpha: 0.6 * glow), blurRadius: 16 * glow),
        ],
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          '$number',
          style: TextStyle(
            fontFamily: TrovoTheme.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.56,
            height: 1,
            color: PaperColors.ink,
          ),
        ),
      ),
    );
  }
}

/// Etichetta con la quantità (es. "12").
class QuantityTag extends StatelessWidget {
  const QuantityTag({super.key, required this.quantity});
  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: TrovoColors.primary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PaperColors.ink, width: 1.3),
      ),
      child: Text(
        '$quantity',
        style: const TextStyle(
          fontFamily: TrovoTheme.fontFamily,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          height: 1.2,
          color: Colors.white,
        ),
      ),
    );
  }
}

class ColorDot extends StatelessWidget {
  const ColorDot({super.key, required this.color, this.size = 14});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
        ),
      );
}

/// Oggetto disegnato come un adesivo sul piano.
class ItemSticker extends StatelessWidget {
  const ItemSticker({super.key, required this.item, this.size = 54, this.tilt = 0, this.glow = 0});

  final Item item;
  final double size;
  final double tilt;
  final double glow;

  @override
  Widget build(BuildContext context) {
    // L'oggetto disegnato come il suo contenitore (barattolo, bottiglia, cesto…).
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          VesselView(item: item, size: math.min(size, size / VesselView.widthFor(item, 1)), glow: glow),
          if (item.quantity > 1) Positioned(right: -6, top: -4, child: QuantityTag(quantity: item.quantity)),
        ],
      ),
    );
  }
}

/// Riga "🥫 Dispensa › ● Scaffale Blu › [3]".
class LocationLine extends StatelessWidget {
  const LocationLine({
    super.key,
    required this.room,
    required this.shelf,
    required this.levelIndex,
    this.showRoom = true,
    this.position,
  });

  final Room room;
  final Shelf shelf;
  final int levelIndex;
  final bool showRoom;

  /// Numero del posto (da 1), se lo vuoi mostrare.
  final int? position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = shelf.levels[levelIndex];
    final sep = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.chevron_right_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
    );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: [
        if (showRoom) ...[
          Text('${room.emoji} ${room.name}', style: theme.textTheme.bodySmall),
          sep,
        ],
        ColorDot(color: TrovoColors.shelf(shelf.colorIndex), size: 12),
        const SizedBox(width: 6),
        Text(shelf.name, style: theme.textTheme.bodySmall?.copyWith(color: TrovoColors.text)),
        sep,
        // Il colore del piano resta visibile: è un aiuto per ricordare.
        LevelTag(
          number: shelf.levelNumber(levelIndex),
          color: TrovoColors.level(level.colorIndex),
          size: 24,
        ),
        if (position != null && position! > 0) ...[
          const SizedBox(width: 6),
          Text(context.s.slot(position!), style: theme.textTheme.bodySmall?.copyWith(color: TrovoColors.text)),
        ],
      ],
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({super.key, required this.value, required this.onChanged, this.min = 1, this.max = 999, this.big = false});

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final size = big ? 56.0 : 44.0;
    Widget btn(IconData icon, bool enabled, int delta) => SizedBox(
          width: size,
          height: size,
          child: IconButton.filledTonal(
            onPressed: enabled
                ? () {
                    HapticFeedback.selectionClick();
                    onChanged(value + delta);
                  }
                : null,
            icon: Icon(icon, size: big ? 28 : 22),
            style: IconButton.styleFrom(
              backgroundColor: TrovoColors.surfaceHigher,
              foregroundColor: TrovoColors.text,
            ),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.remove_rounded, value > min, -1),
        SizedBox(
          width: big ? 64 : 44,
          child: AnimatedSwitcher(
            duration: Motion.of(context, 180),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Text(
              '$value',
              key: ValueKey(value),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: TrovoTheme.fontFamily,
                fontWeight: FontWeight.w800,
                fontSize: big ? 32 : 22,
                color: TrovoColors.text,
              ),
            ),
          ),
        ),
        btn(Icons.add_rounded, value < max, 1),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.art, required this.title, required this.body, this.action});

  final Widget art;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          art,
          const SizedBox(height: 20),
          Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(body,
              style: theme.textTheme.bodyLarge?.copyWith(color: TrovoColors.textMuted),
              textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    );
  }
}

Future<bool> confirmDialog(BuildContext context, String message, {String? confirmLabel, bool danger = true}) async {
  final s = context.s;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message, style: Theme.of(ctx).textTheme.titleMedium),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: TrovoColors.danger, foregroundColor: Colors.black) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel ?? s.delete),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<String?> textPrompt(BuildContext context, {required String title, String initial = '', String? hint}) {
  final controller = TextEditingController(text: initial);
  final s = context.s;
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        style: Theme.of(ctx).textTheme.bodyLarge,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim().isEmpty ? null : v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
        FilledButton(
          onPressed: () {
            final v = controller.text.trim();
            Navigator.pop(ctx, v.isEmpty ? null : v);
          },
          child: Text(s.save),
        ),
      ],
    ),
  );
}

void showToast(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message),
    duration: Duration(seconds: actionLabel != null ? 5 : 2),
    action: actionLabel != null ? SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}) : null,
  ));
}
