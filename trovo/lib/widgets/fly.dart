import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Animazione "Volo": l'emoji vola ad arco fino al suo posto.
Future<void> flyEmoji(
  BuildContext context, {
  required String emoji,
  required Offset from,
  required Offset to,
  double size = 44,
}) async {
  if (Motion.reduced(context)) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late OverlayEntry entry;
  final done = Future<void>.delayed(const Duration(milliseconds: 620));
  entry = OverlayEntry(
    builder: (_) => _FlyingEmoji(
      emoji: emoji,
      from: from,
      to: to,
      size: size,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
  await done;
}

Offset centerOf(GlobalKey key) {
  final box = key.currentContext?.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return Offset.zero;
  return box.localToGlobal(box.size.center(Offset.zero));
}

class _FlyingEmoji extends StatefulWidget {
  const _FlyingEmoji({required this.emoji, required this.from, required this.to, required this.size, required this.onDone});

  final String emoji;
  final Offset from;
  final Offset to;
  final double size;
  final VoidCallback onDone;

  @override
  State<_FlyingEmoji> createState() => _FlyingEmojiState();
}

class _FlyingEmojiState extends State<_FlyingEmoji> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_c.value);
          // Curva di Bézier: sale e poi scende sul posto giusto.
          final control = Offset(
            (widget.from.dx + widget.to.dx) / 2,
            math.min(widget.from.dy, widget.to.dy) - 120,
          );
          final p = Offset(
            _bezier(widget.from.dx, control.dx, widget.to.dx, t),
            _bezier(widget.from.dy, control.dy, widget.to.dy, t),
          );
          final scale = 1.3 - 0.45 * t + 0.25 * math.sin(t * math.pi);
          final opacity = t > 0.9 ? (1 - t) * 10 : 1.0;
          return Stack(
            children: [
              Positioned(
                left: p.dx - widget.size / 2,
                top: p.dy - widget.size / 2,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: (1 - t) * 0.6,
                    child: Transform.scale(
                      scale: scale,
                      child: Text(widget.emoji,
                          style: TextStyle(fontSize: widget.size, decoration: TextDecoration.none)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _bezier(double a, double b, double c, double t) =>
      (1 - t) * (1 - t) * a + 2 * (1 - t) * t * b + t * t * c;
}
