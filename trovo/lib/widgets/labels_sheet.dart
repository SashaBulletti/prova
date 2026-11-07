import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models.dart';
import '../scan_codes.dart';
import '../services/labels_pdf.dart';
import '../store_scope.dart';
import '../theme.dart';
import 'common.dart';

/// Foglio per stampare le etichette QR di uno scaffale (o di tutta la casa).
Future<void> showLabelsSheet(BuildContext context, {Shelf? shelf}) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _LabelsSheet(shelf: shelf),
    );

enum _Kind { slots, items }

class _LabelsSheet extends StatefulWidget {
  const _LabelsSheet({this.shelf});
  final Shelf? shelf;

  @override
  State<_LabelsSheet> createState() => _LabelsSheetState();
}

class _LabelsSheetState extends State<_LabelsSheet> {
  _Kind _kind = _Kind.slots;
  bool _busy = false;

  List<LevelRef> _levels() {
    final all = context.store.allLevels();
    final shelf = widget.shelf;
    return shelf == null ? all : all.where((r) => identical(r.shelf, shelf)).toList();
  }

  List<LabelEntry> _entries() {
    final s = context.s;
    final out = <LabelEntry>[];
    for (final ref in _levels()) {
      final color = TrovoColors.level(ref.level.colorIndex).toARGB32();
      final where = '${ref.shelf.name} · ${s.compartment(ref.level.kind, ref.levelNumber)}';
      if (_kind == _Kind.slots) {
        for (var p = 0; p < ref.level.slotCount; p++) {
          final item = ref.level.itemAt(p);
          out.add(LabelEntry(
            code: TrovoCode.forSlot(ref.level.id, p + 1),
            title: item?.name ?? s.free,
            lines: [where, '${s.slot(p + 1)} · ${ref.room.name}'],
            color: color,
          ));
        }
      } else {
        for (final item in ref.level.items) {
          out.add(LabelEntry(
            code: TrovoCode.forItem(item.id),
            title: item.name,
            lines: [s.jar, where],
            color: color,
          ));
        }
      }
    }
    return out;
  }

  String get _title {
    final s = context.s;
    final what = _kind == _Kind.slots ? s.labelsSlots : s.labelsItems;
    return widget.shelf == null ? what : '$what · ${widget.shelf!.name}';
  }

  Future<void> _go({required bool print}) async {
    final entries = _entries();
    if (entries.isEmpty) {
      showToast(context, context.s.nothingToPrint);
      return;
    }
    setState(() => _busy = true);
    try {
      final title = _title;
      final bytes = await buildLabelsPdf(title: title, entries: entries);
      final file = 'trovo-etichette-${DateTime.now().millisecondsSinceEpoch ~/ 1000}.pdf';
      if (print) {
        await Printing.layoutPdf(onLayout: (_) async => bytes, name: file);
      } else {
        await Printing.sharePdf(bytes: bytes, filename: file);
      }
    } catch (e) {
      debugPrint('Trovo: etichette non riuscite ($e)');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final count = _entries().length;

    Widget option(_Kind kind, IconData icon, String title, String sub) => Card(
          color: _kind == kind ? TrovoColors.primary.withValues(alpha: 0.16) : TrovoColors.surfaceHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: _kind == kind ? TrovoColors.primary : Colors.transparent, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _kind = kind),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(icon, size: 34, color: _kind == kind ? TrovoColors.primary : TrovoColors.textMuted),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(sub, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.labels, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(s.labelsHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            option(_Kind.slots, Icons.view_week_rounded, s.labelsSlots, s.labelsSlotsSub),
            const SizedBox(height: 10),
            option(_Kind.items, Icons.local_drink_rounded, s.labelsItems, s.labelsItemsSub),
            const SizedBox(height: 16),
            Text('🏷️  $count', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : () => _go(print: true),
              icon: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Icon(Icons.print_rounded),
              label: Text(s.print),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _go(print: false),
              icon: const Icon(Icons.download_rounded),
              label: Text(s.saveOrShare),
            ),
          ],
        ),
      ),
    );
  }
}
