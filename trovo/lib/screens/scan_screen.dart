import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../scan_codes.dart';
import '../services/product_lookup.dart';
import '../store_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/photo_update.dart';
import '../widgets/sheets.dart';
import 'shelf_screen.dart';

/// Apre la fotocamera e restituisce il primo codice a barre letto.
Future<String?> scanBarcode(BuildContext context) => Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanScreen(pickOnly: true)),
    );

/// Scanner: QR dei posti, QR dei barattoli, codici a barre dei prodotti.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.pickOnly = false});

  /// true: restituisce solo il codice letto (per il foglio "Aggiungi").
  final bool pickOnly;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final raw = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (raw == null) return;
    _handled = true;
    HapticFeedback.mediumImpact();

    if (widget.pickOnly) {
      Navigator.of(context).pop(raw);
      return;
    }

    final store = context.store;
    final s = context.s;
    final code = TrovoCode.parse(raw);
    final nav = Navigator.of(context);

    if (code != null && code.kind == TrovoCodeKind.slot) {
      final ref = store.findLevel(code.id);
      if (ref != null && code.position <= ref.level.slotCount) {
        nav.pushReplacement(MaterialPageRoute(
          builder: (_) => ShelfScreen(
            shelfId: ref.shelf.id,
            highlightLevelId: ref.level.id,
            highlightSlot: code.position - 1,
          ),
        ));
        return;
      }
      _retry(s.codeNotFound);
      return;
    }

    if (code != null && code.kind == TrovoCodeKind.item) {
      final found = store.findItemWithLevel(code.id);
      final ref = found == null ? null : store.findLevel(found.level.id);
      if (found != null && ref != null) {
        nav.pushReplacement(MaterialPageRoute(
          builder: (_) => ShelfScreen(
            shelfId: ref.shelf.id,
            highlightLevelId: ref.level.id,
            highlightItemId: found.item.id,
          ),
        ));
        return;
      }
      _retry(s.codeNotFound);
      return;
    }

    if (raw.startsWith('trovo:')) {
      _retry(s.unknownCode);
      return;
    }

    // Codice a barre di un prodotto: è già negli scaffali?
    final item = store.findByBarcode(raw);
    if (item != null) {
      final found = store.findItemWithLevel(item.id)!;
      final ref = store.findLevel(found.level.id)!;
      nav.pushReplacement(MaterialPageRoute(
        builder: (_) => ShelfScreen(
          shelfId: ref.shelf.id,
          highlightLevelId: ref.level.id,
          highlightItemId: item.id,
        ),
      ));
      return;
    }

    // Non c'è: proponi di aggiungerlo, con il nome preso da Open Food Facts.
    await _controller.stop();
    if (!mounted) return;
    final add = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('🤔', style: TextStyle(fontSize: 48), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(s.productNotHere, style: Theme.of(ctx).textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.add_rounded),
                label: Text(s.addIt),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (add != true) {
      _handled = false;
      await _controller.start();
      return;
    }
    showToast(context, s.lookingUp);
    final name = await lookupProductName(raw, italian: s.it);
    if (!mounted) return;
    if (name == null) showToast(context, s.productNotFound);
    nav.pop();
    if (nav.context.mounted) {
      showAddItemSheet(nav.context, initialName: name ?? '', barcode: raw);
    }
  }

  void _retry(String message) {
    showToast(context, message);
    Future.delayed(const Duration(milliseconds: 1500), () => _handled = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.pickOnly ? s.scanBarcode : s.scan),
        actions: [
          IconButton(
            iconSize: 28,
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(s.cameraUnavailable, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
          // Riquadro dove inquadrare.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: TrovoColors.primary, width: 4),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.pickOnly ? s.scanBarcodeHint : s.scanHint,
                      style: theme.textTheme.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (!widget.pickOnly) ...[
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () async {
                        await _controller.stop();
                        if (!context.mounted) return;
                        await runPhotoUpdate(context);
                        if (mounted) await _controller.start();
                      },
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: Text(s.photoUpdate),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
