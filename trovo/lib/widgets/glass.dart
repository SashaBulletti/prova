import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// "Vetro solido": per chi si distrae con lo sfondo, il vetro diventa opaco.
class GlassStyle {
  static final solid = ValueNotifier<bool>(false);
}

/// Sfondo dell'app: base scura con macchie di colore morbide e un filo di grana.
/// [tint] colora leggermente la macchia in alto a destra (es. il colore della stanza).
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key, required this.child, this.tint});
  final Widget child;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: TrovoColors.background),
      child: Stack(
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: tint ?? const Color(0xFF6366F1)),
              duration: Motion.of(context, 600),
              builder: (context, c, _) => CustomPaint(painter: _AuroraPainter(topRight: c!)),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.035,
                child: Image.asset('assets/textures/grain.png', repeat: ImageRepeat.repeat, filterQuality: FilterQuality.none),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.topRight});
  final Color topRight;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 0.75;
    void blob(Offset center, Color color, double alpha) {
      final rect = Rect.fromCircle(center: center, radius: r);
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
          ).createShader(rect),
      );
    }

    blob(Offset(-size.width * 0.1, size.height * 0.02), TrovoColors.primary, 0.20);
    blob(Offset(size.width * 1.05, size.height * 0.10), topRight, 0.26);
    blob(Offset(size.width * 0.55, size.height * 1.02), const Color(0xFFA855F7), 0.14);
    blob(Offset(-size.width * 0.05, size.height * 0.85), const Color(0xFFF59E0B), 0.07);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.topRight != topRight;
}

/// Vetro leggero (senza sfocatura): per card e tessere.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = EdgeInsets.zero,
    this.tint,
    this.tintAlpha = 0.14,
    this.borderColor,
    this.onTap,
    this.onLongPress,
    this.shadow = true,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  final double tintAlpha;
  final Color? borderColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null || onLongPress != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: br,
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          onLongPress: onLongPress,
          child: content,
        ),
      );
      content = PressScale(child: content);
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: br,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tint == null
              ? [Colors.white.withValues(alpha: 0.10), Colors.white.withValues(alpha: 0.04)]
              : [tint!.withValues(alpha: tintAlpha + 0.04), tint!.withValues(alpha: tintAlpha * 0.5)],
        ),
        boxShadow: shadow
            ? [
                BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 32, offset: const Offset(0, 16)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 4, offset: const Offset(0, 1)),
              ]
            : null,
      ),
      foregroundDecoration: _GlassEdge(radius: radius, color: borderColor),
      child: ClipRRect(borderRadius: br, child: content),
    );
  }
}

/// Bordo del vetro: più luminoso in alto a sinistra, con riflesso in alto.
class _GlassEdge extends Decoration {
  const _GlassEdge({required this.radius, this.color, this.maxAlpha = 0.38});
  final double radius;
  final Color? color;
  final double maxAlpha;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _GlassEdgePainter(this);
}

class _GlassEdgePainter extends BoxPainter {
  _GlassEdgePainter(this.d);
  final _GlassEdge d;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
    final rect = offset & size;
    final rrect = RRect.fromRectAndRadius(rect.deflate(0.5), Radius.circular(d.radius));
    final c = d.color;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = c == null ? 1 : 1.5
      ..shader = c != null
          ? LinearGradient(colors: [c.withValues(alpha: 0.9), c.withValues(alpha: 0.5)]).createShader(rect)
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: d.maxAlpha),
                Colors.white.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.16),
              ],
              stops: const [0, 0.5, 1],
            ).createShader(rect);
    canvas.drawRRect(rrect, stroke);
    // Riflesso nella parte alta.
    final top = Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.35);
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      top,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.07), Colors.white.withValues(alpha: 0)],
        ).createShader(top),
    );
    canvas.restore();
  }
}

/// Vetro spesso con sfocatura: per barre e fogli che galleggiano.
class GlassBar extends StatelessWidget {
  const GlassBar({super.key, required this.child, this.radius = 32, this.sigma = 30, this.padding = EdgeInsets.zero, this.borderRadius});

  final Widget child;
  final double radius;
  final double sigma;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(radius);
    return ValueListenableBuilder<bool>(
      valueListenable: GlassStyle.solid,
      builder: (context, solid, _) {
        final body = Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: br,
            color: solid ? TrovoColors.solidGlass : TrovoColors.background.withValues(alpha: 0.45),
            gradient: solid
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white.withValues(alpha: 0.10), Colors.white.withValues(alpha: 0.05)],
                  ),
          ),
          foregroundDecoration: _GlassEdge(radius: br.topLeft.x, maxAlpha: 0.45),
          child: child,
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: br,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 12))],
          ),
          child: ClipRRect(
            borderRadius: br,
            child: solid
                ? body
                : BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                    child: ColoredBox(color: TrovoColors.background.withValues(alpha: 0.45), child: body),
                  ),
          ),
        );
      },
    );
  }
}

/// Foglio dal basso in vetro sfocato.
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool scrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: scrollControlled,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: GlassBar(
        sigma: 40,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 14),
            Flexible(child: builder(ctx)),
          ],
        ),
      ),
    ),
  );
}

/// Bottone principale: capsula con gradiente dell'accento e riflesso.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon, this.busy = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return PressScale(
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(colors: [TrovoColors.primary, TrovoColors.primaryEnd]),
            boxShadow: [
              BoxShadow(color: TrovoColors.primary.withValues(alpha: 0.30), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Colors.white.withValues(alpha: 0.25), Colors.white.withValues(alpha: 0)],
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: enabled
                  ? () {
                      HapticFeedback.lightImpact();
                      onPressed!();
                    }
                  : null,
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: TrovoColors.onPrimary),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: TrovoColors.onPrimary, size: 22),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: const TextStyle(
                              fontFamily: TrovoTheme.fontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: TrovoColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottone tondo di vetro (es. impostazioni, indietro).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.onPressed, this.tooltip, this.size = 44, this.color});
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: size,
      height: size,
      child: GlassCard(
        radius: size / 2,
        shadow: false,
        onTap: onPressed,
        child: Center(child: Icon(icon, size: size * 0.48, color: color ?? TrovoColors.text)),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Quando premi, l'elemento si abbassa un poco (scala 0.96).
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child});
  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: Duration(milliseconds: _down ? 90 : 220),
        curve: _down ? Curves.easeOut : Motion.snappy,
        child: widget.child,
      ),
    );
  }
}

/// Icona dentro un cerchio di vetro (stati vuoti).
class GlassBadgeIcon extends StatelessWidget {
  const GlassBadgeIcon({super.key, required this.icon, this.size = 96, this.color});
  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: GlassCard(
        radius: size / 2,
        tint: color,
        child: Center(child: Icon(icon, size: size * 0.42, color: color ?? TrovoColors.primaryOnGlass)),
      ),
    );
  }
}
