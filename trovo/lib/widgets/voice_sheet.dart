import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/voice.dart';
import '../store_scope.dart';
import '../theme.dart';
import 'glass.dart';

/// Apre il foglio "Ti ascolto…" e restituisce le parole capite.
Future<String?> listenForWords(BuildContext context) async {
  HapticFeedback.lightImpact();
  final result = await showGlassSheet<String>(context, builder: (_) => const _VoiceSheet());
  return (result == null || result.trim().isEmpty) ? null : result.trim();
}

class _VoiceSheet extends StatefulWidget {
  const _VoiceSheet();

  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  String _words = '';
  double _level = 0;
  bool _closing = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final s = context.s;
    final ok = await Voice.instance.listen(
      localeTag: s.localeTag,
      onWords: (words, isFinal) {
        if (!mounted) return;
        setState(() => _words = words);
        if (isFinal) _finish();
      },
      onLevel: (l) {
        if (mounted) setState(() => _level = l);
      },
      onError: (_) {
        if (!mounted) return;
        if (_words.isNotEmpty) {
          _finish();
        } else {
          setState(() => _failed = true);
        }
      },
      onDone: () {
        if (mounted && _words.isNotEmpty) _finish();
      },
    );
    if (!ok && mounted) setState(() => _failed = true);
  }

  void _finish() {
    if (_closing) return;
    _closing = true;
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) Navigator.pop(context, _words);
    });
  }

  @override
  void dispose() {
    _breath.dispose();
    Voice.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final words = _words.trim().isEmpty ? <String>[] : _words.trim().split(RegExp(r'\s+'));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _failed ? '' : (words.isEmpty ? s.listening : ''),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                if (_failed) {
                  Navigator.pop(context);
                } else if (_words.isNotEmpty) {
                  Voice.instance.stop();
                  _finish();
                } else {
                  Voice.instance.cancel();
                  Navigator.pop(context);
                }
              },
              child: AnimatedBuilder(
                animation: _breath,
                builder: (context, child) {
                  final reduced = Motion.reduced(context);
                  final ring = reduced ? 1.0 : 1 + 0.08 * _breath.value + 0.45 * _level;
                  return SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: ring,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (_failed ? TrovoColors.danger : TrovoColors.primary).withValues(alpha: 0.16),
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: reduced ? 1 : 1 + 0.2 * _level,
                          child: Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (_failed ? TrovoColors.danger : TrovoColors.primary).withValues(alpha: 0.28),
                            ),
                          ),
                        ),
                        child!,
                      ],
                    ),
                  );
                },
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _failed ? TrovoColors.danger : TrovoColors.primary,
                  ),
                  child: Icon(
                    _failed ? Icons.mic_off_rounded : Icons.mic_rounded,
                    size: 42,
                    color: _failed ? Colors.black : TrovoColors.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_failed)
              Text(s.voiceUnavailable, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge)
            else if (words.isEmpty)
              Text(s.sayItemName, style: theme.textTheme.bodyLarge?.copyWith(color: TrovoColors.textMuted))
            else
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < words.length; i++)
                    Chip(
                      key: ValueKey('$i-${words[i]}'),
                      label: Text(words[i], style: theme.textTheme.titleMedium),
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                    )
                        .animate()
                        .fadeIn(duration: Motion.of(context, 200))
                        .scale(begin: const Offset(0.6, 0.6), curve: Curves.easeOutBack, duration: Motion.of(context, 260)),
                ],
              ),
            const SizedBox(height: 16),
            if (!_failed)
              Text(s.tapToStop, style: theme.textTheme.bodySmall),
            if (_failed)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(s.done)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottone microfono rotondo, usato in più punti.
class MicButton extends StatelessWidget {
  const MicButton({super.key, required this.onPressed, this.size = 48, this.tooltip});

  final VoidCallback onPressed;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? context.s.searchByVoice,
      child: Material(
        color: TrovoColors.primary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(Icons.mic_rounded, color: TrovoColors.onPrimary, size: size * 0.52),
          ),
        ),
      ),
    );
  }
}
