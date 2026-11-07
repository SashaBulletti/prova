import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../scan_codes.dart';
import '../store_scope.dart';
import '../theme.dart';
import 'common.dart';

/// "Aggiorna con una foto": fotografi un piano, Trovo legge tutti i QR
/// (posti e barattoli) e sposta le cose al posto giusto. Niente AI:
/// il riconoscimento dei QR è già dentro il telefono, gratis e senza internet.
Future<void> runPhotoUpdate(BuildContext context) async {
  final s = context.s;
  if (kIsWeb) {
    showToast(context, s.photoNotSupported);
    return;
  }
  XFile? photo;
  try {
    photo = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 3000, imageQuality: 92);
  } catch (e) {
    debugPrint('Trovo: fotocamera non disponibile ($e)');
  }
  if (photo == null || !context.mounted) return;

  // Mentre leggo, mostro un messaggio.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      content: Row(
        children: [
          const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(width: 18),
          Expanded(child: Text(s.photoReading)),
        ],
      ),
    ),
  );

  final codes = <ScannedCode>[];
  final controller = MobileScannerController(autoStart: false, formats: const [BarcodeFormat.qrCode]);
  try {
    final capture = await controller.analyzeImage(photo.path, formats: const [BarcodeFormat.qrCode]);
    for (final b in capture?.barcodes ?? const <Barcode>[]) {
      final raw = b.rawValue;
      if (raw == null || b.corners.isEmpty) continue;
      final xs = b.corners.map((o) => o.dx);
      final ys = b.corners.map((o) => o.dy);
      codes.add(ScannedCode(
        raw,
        Rect.fromLTRB(xs.reduce(math.min), ys.reduce(math.min), xs.reduce(math.max), ys.reduce(math.max)),
      ));
    }
  } catch (e) {
    debugPrint('Trovo: lettura foto non riuscita ($e)');
  } finally {
    controller.dispose();
  }
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();

  final store = context.store;
  final plan = planFromPhoto(
    codes,
    findLevel: (id) => store.findLevel(id)?.level,
    findItem: store.findItemWithLevel,
  );

  if (plan.slotCodes == 0 && plan.itemCodes == 0) {
    showToast(context, s.photoNoCodes);
    return;
  }
  if (plan.itemCodes > 0 && plan.slotCodes == 0) {
    showToast(context, s.photoNoSlots);
    return;
  }
  if (plan.moves.isEmpty) {
    HapticFeedback.lightImpact();
    showToast(context, s.photoAllGood(plan.unchanged.length));
    return;
  }

  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _ConfirmMoves(plan: plan),
  );
  if (ok == true && context.mounted) {
    store.applyPhotoMoves(plan.moves);
    HapticFeedback.mediumImpact();
    showToast(context, s.photoApplied(plan.moves.length));
  }
}

class _ConfirmMoves extends StatelessWidget {
  const _ConfirmMoves({required this.plan});
  final PhotoPlan plan;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final store = context.store;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.photoChanges, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 14),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final m in plan.moves)
                    Builder(builder: (context) {
                      final ref = store.findLevel(m.toLevel.id);
                      final where = ref == null
                          ? ''
                          : '${ref.shelf.name} · ${s.compartment(ref.level.kind, ref.levelNumber)} · ${s.slot(m.start + 1)}';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Text(m.item.emoji, style: const TextStyle(fontSize: 30)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.item.name, style: theme.textTheme.titleSmall),
                                  Text('→ $where', style: theme.textTheme.bodySmall?.copyWith(color: TrovoColors.primary)),
                                  Text(s.seen(m.seen), style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check_rounded),
              label: Text(s.confirm),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel)),
          ],
        ),
      ),
    );
  }
}
