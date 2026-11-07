import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../icons.dart';

import '../models.dart';
import '../room_icons.dart';
import '../store_scope.dart';
import '../theme.dart';
import 'glass.dart';

/// Numero del piano: pallino nel colore del piano + numero scuro.
/// Colore e numero insieme: due indizi, funziona anche per chi è daltonico.
class LevelTag extends StatelessWidget {
  const LevelTag({super.key, required this.number, required this.color, this.size = 28, this.glow = 0});

  final int number;
  final Color color;
  final double size;
  final double glow;

  @override
  Widget build(BuildContext context) {
    final bg = Color.lerp(color, TrovoColors.found, glow)!;
    return Container(
      constraints: BoxConstraints(minWidth: size),
      height: size,
      padding: EdgeInsets.symmetric(horizontal: number > 9 ? size * 0.18 : 0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size / 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(bg, Colors.white, 0.18)!, bg],
        ),
        boxShadow: [
          BoxShadow(color: bg.withValues(alpha: 0.35 + 0.3 * glow), blurRadius: 10 + 14 * glow),
        ],
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          '$number',
          style: TextStyle(
            fontFamily: TrovoTheme.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.5,
            height: 1,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: TrovoColors.background,
          ),
        ),
      ),
    );
  }
}

class ColorDot extends StatelessWidget {
  const ColorDot({super.key, required this.color, this.size = 10});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: size)],
        ),
      );
}

/// Un oggetto come tessera di vetro con l'emoji.
class ItemSticker extends StatelessWidget {
  const ItemSticker({super.key, required this.item, this.size = 54, this.tint, this.glow = 0, this.showQuantity = true});

  final Item item;
  final double size;
  final Color? tint;
  final double glow;
  final bool showQuantity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GlassTile(size: size, tint: tint, glow: glow, emoji: item.emoji),
        if (showQuantity && item.quantity > 1)
          Positioned(right: -5, top: -5, child: QuantityBadge(quantity: item.quantity)),
      ],
    );
  }
}

/// Tessera di vetro 3D: tinta leggera, riflesso in alto, ombra di contatto.
class GlassTile extends StatelessWidget {
  const GlassTile({super.key, required this.size, required this.emoji, this.tint, this.glow = 0, this.darken = 0});

  final double size;
  final String emoji;
  final Color? tint;
  final double glow;
  final double darken;

  @override
  Widget build(BuildContext context) {
    final t = tint ?? Colors.white;
    final radius = size * 0.24;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(t.withValues(alpha: 0.20), const Color(0xFF232733)),
            Color.alphaBlend(t.withValues(alpha: 0.08), const Color(0xFF171A21)),
          ],
        ),
        border: Border.all(
          color: Color.lerp(Colors.white.withValues(alpha: 0.18), TrovoColors.found, glow)!,
          width: glow > 0 ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 8, offset: Offset(0, size * 0.08)),
          if (glow > 0) BoxShadow(color: TrovoColors.found.withValues(alpha: 0.55 * glow), blurRadius: 24 * glow),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: darken),
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
      alignment: Alignment.center,
      child: Opacity(
        opacity: (1 - darken * 0.9).clamp(0.3, 1.0),
        child: Text(emoji, style: TextStyle(fontSize: size * 0.56, height: 1.1)),
      ),
    );
  }
}

class QuantityBadge extends StatelessWidget {
  const QuantityBadge({super.key, required this.quantity});
  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: TrovoColors.background.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          '$quantity',
          style: const TextStyle(
            fontFamily: TrovoTheme.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            height: 1,
            fontFeatures: [FontFeature.tabularFigures()],
            color: TrovoColors.text,
          ),
        ),
      ),
    );
  }
}

/// Riga "Dispensa › • Scaffale Blu › (3) · Posto 2".
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
    const sep = Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(PIcons.caretRight, size: 14, color: TrovoColors.textFaint),
    );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: [
        if (showRoom) ...[
          Icon(roomIcon(room.icon), size: 16, color: TrovoColors.textMuted),
          const SizedBox(width: 4),
          Text(room.name, style: theme.textTheme.bodySmall),
          sep,
        ],
        ColorDot(color: TrovoColors.shelf(shelf.colorIndex), size: 8),
        const SizedBox(width: 6),
        Text(shelf.name, style: theme.textTheme.bodySmall?.copyWith(color: TrovoColors.text)),
        sep,
        LevelTag(number: shelf.levelNumber(levelIndex), color: TrovoColors.level(level.colorIndex), size: 22),
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
    final size = big ? 52.0 : 44.0;
    Widget btn(IconData icon, bool enabled, int delta) => Opacity(
          opacity: enabled ? 1 : 0.35,
          child: GlassIconButton(
            icon: icon,
            size: size,
            onPressed: enabled
                ? () {
                    HapticFeedback.selectionClick();
                    onChanged(value + delta);
                  }
                : null,
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(PIcons.minus, value > min, -1),
        SizedBox(
          width: big ? 60 : 44,
          child: AnimatedSwitcher(
            duration: Motion.of(context, 180),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: Tween(begin: 0.8, end: 1.0).animate(anim), child: child),
            ),
            child: Text(
              '$value',
              key: ValueKey(value),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: TrovoTheme.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: big ? 28 : 20,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: TrovoColors.text,
              ),
            ),
          ),
        ),
        btn(PIcons.plus, value < max, 1),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body, this.action});

  final IconData icon;
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
          GlassBadgeIcon(icon: icon),
          const SizedBox(height: 22),
          Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyLarge?.copyWith(color: TrovoColors.textMuted), textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    );
  }
}

/// Titolo di sezione (es. "Colore", "Quanti piani?").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 6),
        child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: TrovoColors.textMuted)),
      );
}

Future<bool> confirmDialog(BuildContext context, String message, {String? confirmLabel, bool danger = true}) async {
  final s = context.s;
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => AlertDialog(
      content: Text(message, style: Theme.of(ctx).textTheme.titleSmall),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: TrovoColors.textMuted),
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(s.cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: danger ? TrovoColors.danger : TrovoColors.primaryOnGlass),
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
        TextButton(
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
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message),
    duration: Duration(seconds: actionLabel != null ? 5 : 2),
    action: actionLabel != null ? SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}) : null,
  ));
}
