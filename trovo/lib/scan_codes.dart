import 'dart:ui';

import 'models.dart';

/// I QR code di Trovo.
///  - Posto:    `trovo:p:idPiano:numeroPosto`   (si attacca sotto il posto)
///  - Oggetto:  `trovo:i:idOggetto`             (si attacca sul barattolo)
class TrovoCode {
  const TrovoCode._(this.kind, this.id, this.position);

  final TrovoCodeKind kind;

  /// Id del piano (per i posti) o dell'oggetto (per i barattoli).
  final String id;

  /// Numero del posto, da 1. Solo per i posti.
  final int position;

  static String forSlot(String levelId, int positionNumber) => 'trovo:p:$levelId:$positionNumber';
  static String forItem(String itemId) => 'trovo:i:$itemId';

  static TrovoCode? parse(String? raw) {
    if (raw == null) return null;
    final parts = raw.trim().split(':');
    if (parts.length < 3 || parts[0] != 'trovo') return null;
    if (parts[1] == 'p' && parts.length == 4) {
      final pos = int.tryParse(parts[3]);
      if (pos == null || pos < 1) return null;
      return TrovoCode._(TrovoCodeKind.slot, parts[2], pos);
    }
    if (parts[1] == 'i' && parts.length == 3) {
      return TrovoCode._(TrovoCodeKind.item, parts[2], 0);
    }
    return null;
  }
}

enum TrovoCodeKind { slot, item }

/// Un codice trovato in una foto, con la sua posizione nell'immagine.
class ScannedCode {
  const ScannedCode(this.raw, this.box);
  final String raw;
  final Rect box;
}

/// Una modifica proposta dopo aver letto una foto.
class PhotoMove {
  const PhotoMove({
    required this.item,
    required this.fromLevel,
    required this.toLevel,
    required this.start,
    required this.span,
    required this.seen,
  });

  final Item item;
  final Level fromLevel;
  final Level toLevel;

  /// Primo posto (da 0) e quanti posti occupa.
  final int start;
  final int span;

  /// Quanti barattoli con questo QR si vedono nella foto.
  final int seen;
}

class PhotoPlan {
  const PhotoPlan({required this.moves, required this.unchanged, required this.slotCodes, required this.itemCodes});
  final List<PhotoMove> moves;
  final List<Item> unchanged;
  final int slotCodes;
  final int itemCodes;
}

/// Capisce dalla foto quale barattolo sta sopra quale posto.
/// Per ogni QR di un barattolo cerca il QR di posto più vicino in orizzontale,
/// tra quelli che stanno più in basso (sono attaccati sotto, sul bordo del piano).
PhotoPlan planFromPhoto(
  List<ScannedCode> codes, {
  required Level? Function(String levelId) findLevel,
  required ({Level level, Item item})? Function(String itemId) findItem,
}) {
  final slots = <({TrovoCode code, Rect box, Level level})>[];
  final items = <({TrovoCode code, Rect box})>[];
  final seenRaw = <String>{};
  for (final c in codes) {
    final code = TrovoCode.parse(c.raw);
    if (code == null) continue;
    if (code.kind == TrovoCodeKind.slot) {
      // Lo stesso QR di posto letto due volte conta una volta sola.
      if (!seenRaw.add('${c.raw}@${c.box.center.dx.round() ~/ 20}')) continue;
      final level = findLevel(code.id);
      if (level == null || code.position > level.slotCount) continue;
      slots.add((code: code, box: c.box, level: level));
    } else {
      items.add((code: code, box: c.box));
    }
  }

  final targets = <String, List<({Level level, int pos})>>{};
  for (final it in items) {
    if (slots.isEmpty) break;
    final c = it.box.center;
    final below = slots.where((s) => s.box.center.dy > c.dy - it.box.height * 0.25).toList();
    final pool = below.isEmpty ? slots : below;
    pool.sort((a, b) {
      double cost(Rect r) => (r.center.dx - c.dx).abs() + 0.35 * (r.center.dy - c.dy).abs();
      return cost(a.box).compareTo(cost(b.box));
    });
    final best = pool.first;
    targets.putIfAbsent(it.code.id, () => []).add((level: best.level, pos: best.code.position - 1));
  }

  final moves = <PhotoMove>[];
  final unchanged = <Item>[];
  targets.forEach((itemId, places) {
    final found = findItem(itemId);
    if (found == null) return;
    // Il piano più votato, poi i posti distinti su quel piano.
    final byLevel = <Level, List<int>>{};
    for (final p in places) {
      byLevel.putIfAbsent(p.level, () => []).add(p.pos);
    }
    final level = byLevel.entries.reduce((a, b) => a.value.length >= b.value.length ? a : b).key;
    final positions = byLevel[level]!.toSet().toList()..sort();
    final start = positions.first;
    final span = positions.last - positions.first + 1;
    final current = found.level.positionsOf(itemId);
    final same = identical(found.level, level) &&
        current.isNotEmpty &&
        current.first == start &&
        current.length == span;
    if (same) {
      unchanged.add(found.item);
    } else {
      moves.add(PhotoMove(
        item: found.item,
        fromLevel: found.level,
        toLevel: level,
        start: start,
        span: span,
        seen: places.length,
      ));
    }
  });

  return PhotoPlan(moves: moves, unchanged: unchanged, slotCodes: slots.length, itemCodes: items.length);
}
