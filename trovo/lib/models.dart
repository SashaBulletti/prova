import 'dart:math';

/// Struttura: Stanza → Scaffale → Piano → Oggetto.

final _rng = Random();

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_rng.nextInt(1 << 20).toRadixString(36)}';

class Item {
  Item({
    String? id,
    required this.name,
    this.emoji = '📦',
    this.quantity = 1,
    this.note = '',
    this.barcode,
    int? addedAt,
  })  : id = id ?? newId(),
        addedAt = addedAt ?? DateTime.now().millisecondsSinceEpoch;

  final String id;
  String name;
  String emoji;
  int quantity;
  String note;

  /// Codice a barre del prodotto (EAN), se l'hai scansionato.
  String? barcode;
  int addedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'quantity': quantity,
        'note': note,
        'barcode': barcode,
        'addedAt': addedAt,
      };

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        id: j['id'] as String?,
        name: (j['name'] as String?) ?? '',
        emoji: (j['emoji'] as String?) ?? '📦',
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        note: (j['note'] as String?) ?? '',
        barcode: j['barcode'] as String?,
        addedAt: (j['addedAt'] as num?)?.toInt(),
      );
}

/// Che tipo di scomparto è: ripiano, cassetto, asta con grucce, cubo.
enum LevelKind { board, drawer, rail, cube }

LevelKind levelKindFrom(Object? v) =>
    LevelKind.values.firstWhere((k) => k.name == v, orElse: () => LevelKind.board);

/// Che tipo di mobile è.
enum FurnitureKind { shelf, drawers, wardrobe, cubes, cabinet }

FurnitureKind furnitureKindFrom(Object? v) =>
    FurnitureKind.values.firstWhere((k) => k.name == v, orElse: () => FurnitureKind.shelf);

/// Posizione e misura sulla mappa della casa.
/// Per le stanze: in metri circa. Per i mobili: dentro la stanza, da 0 a 1.
class MapBox {
  MapBox(this.x, this.y, this.w, this.h);
  double x;
  double y;
  double w;
  double h;

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'w': w, 'h': h};

  static MapBox? fromJson(Object? j) {
    if (j is! Map) return null;
    double v(String k) => (j[k] as num?)?.toDouble() ?? 0;
    return MapBox(v('x'), v('y'), v('w'), v('h'));
  }
}

/// Un tratto di piano: un oggetto (su uno o più posti) o un posto libero.
class SlotBlock {
  const SlotBlock({required this.start, required this.span, this.item});
  final int start;
  final int span;
  final Item? item;
  bool get isEmpty => item == null;
}

/// Un piano: una fila di posti da sinistra a destra, come sullo scaffale vero.
/// Ogni posto è libero (null) oppure contiene l'id di un oggetto.
/// Un oggetto può occupare più posti vicini (es. 12 pomarole su 2 file).
class Level {
  Level({
    String? id,
    required this.colorIndex,
    this.photoPath,
    List<Item>? items,
    List<String?>? slots,
    int slotCount = defaultSlots,
    this.kind = LevelKind.board,
    this.columns = 3,
  })  : id = id ?? newId(),
        items = items ?? [],
        slots = slots ?? List<String?>.filled(slotCount, null, growable: true);

  static const defaultSlots = 5;

  final String id;
  int colorIndex;
  String? photoPath;
  final List<Item> items;

  /// Ripiano, cassetto, asta o cubo.
  LevelKind kind;

  /// Quanti posti per riga quando lo scomparto si vede dall'alto (cassetti, cubi).
  int columns;

  /// Posti da sinistra a destra.
  final List<String?> slots;

  int get slotCount => slots.length;
  int get freeCount => slots.where((s) => s == null).length;
  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);

  Item? itemById(String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  Item? itemAt(int pos) => (pos >= 0 && pos < slots.length && slots[pos] != null) ? itemById(slots[pos]!) : null;

  List<int> positionsOf(String itemId) => [
        for (var i = 0; i < slots.length; i++)
          if (slots[i] == itemId) i,
      ];

  /// Primo posto dell'oggetto (0 = il più a sinistra), -1 se non c'è.
  int positionOf(String itemId) => slots.indexOf(itemId);

  int spanOf(String itemId) => slots.where((s) => s == itemId).length;

  /// Il piano diviso in blocchi: oggetti (anche su più posti) e posti liberi.
  List<SlotBlock> get blocks {
    final out = <SlotBlock>[];
    var i = 0;
    while (i < slots.length) {
      final id = slots[i];
      if (id == null) {
        out.add(SlotBlock(start: i, span: 1));
        i++;
        continue;
      }
      var j = i + 1;
      while (j < slots.length && slots[j] == id) {
        j++;
      }
      out.add(SlotBlock(start: i, span: j - i, item: itemById(id)));
      i = j;
    }
    return out;
  }

  /// Sistema eventuali incoerenze (oggetti senza posto, posti con oggetti spariti).
  void normalize() {
    final ids = items.map((i) => i.id).toSet();
    for (var i = 0; i < slots.length; i++) {
      if (slots[i] != null && !ids.contains(slots[i])) slots[i] = null;
    }
    for (final item in items) {
      if (!slots.contains(item.id)) {
        final free = slots.indexOf(null);
        if (free >= 0) {
          slots[free] = item.id;
        } else {
          slots.add(item.id);
        }
      }
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'colorIndex': colorIndex,
        'photoPath': photoPath,
        'slots': slots,
        'kind': kind.name,
        'columns': columns,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory Level.fromJson(Map<String, dynamic> j) {
    final items = ((j['items'] as List?) ?? [])
        .map((e) => Item.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final rawSlots = j['slots'] as List?;
    final List<String?> slots;
    if (rawSlots != null) {
      slots = rawSlots.map((e) => e as String?).toList();
    } else {
      // Dati della versione 1: gli oggetti vanno in fila da sinistra,
      // e il piano ha almeno 5 posti.
      slots = [for (final i in items) i.id];
      while (slots.length < defaultSlots) {
        slots.add(null);
      }
    }
    final level = Level(
      id: j['id'] as String?,
      colorIndex: (j['colorIndex'] as num?)?.toInt() ?? 0,
      photoPath: j['photoPath'] as String?,
      items: items,
      slots: slots,
      kind: levelKindFrom(j['kind']),
      columns: (j['columns'] as num?)?.toInt() ?? 3,
    );
    level.normalize();
    return level;
  }
}

class Shelf {
  Shelf({
    String? id,
    required this.name,
    required this.colorIndex,
    this.numberFromTop = true,
    this.kind = FurnitureKind.shelf,
    this.gridColumns = 1,
    this.mapBox,
    List<Level>? levels,
  })  : id = id ?? newId(),
        levels = levels ?? [];

  final String id;
  String name;
  int colorIndex;

  /// Scaffale, cassettiera, armadio, libreria a cubi, mobile chiuso.
  FurnitureKind kind;

  /// Per la libreria a cubi: quanti cubi per riga.
  int gridColumns;

  /// Dove sta nella stanza (mappa). null = posizione automatica.
  MapBox? mapBox;

  /// true: il piano 1 è quello in alto. false: il piano 1 è quello in basso.
  bool numberFromTop;

  /// I piani sono sempre salvati dall'alto verso il basso, come li vedi.
  final List<Level> levels;

  /// Numero dello scomparto, contato tra quelli dello stesso tipo
  /// (piano 1, 2, 3… e cassetto 1, 2… separati).
  int levelNumber(int index) {
    if (index < 0 || index >= levels.length) return index + 1;
    final k = levels[index].kind;
    var pos = 0;
    var total = 0;
    for (var i = 0; i < levels.length; i++) {
      if (levels[i].kind != k) continue;
      if (i < index) pos++;
      total++;
    }
    return numberFromTop ? pos + 1 : total - pos;
  }

  int get itemCount => levels.fold(0, (sum, l) => sum + l.items.length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorIndex': colorIndex,
        'numberFromTop': numberFromTop,
        'kind': kind.name,
        'gridColumns': gridColumns,
        if (mapBox != null) 'map': mapBox!.toJson(),
        'levels': levels.map((l) => l.toJson()).toList(),
      };

  factory Shelf.fromJson(Map<String, dynamic> j) => Shelf(
        id: j['id'] as String?,
        name: (j['name'] as String?) ?? '',
        colorIndex: (j['colorIndex'] as num?)?.toInt() ?? 0,
        numberFromTop: (j['numberFromTop'] as bool?) ?? true,
        kind: furnitureKindFrom(j['kind']),
        gridColumns: (j['gridColumns'] as num?)?.toInt() ?? 1,
        mapBox: MapBox.fromJson(j['map']),
        levels: ((j['levels'] as List?) ?? [])
            .map((e) => Level.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class Room {
  Room({String? id, required this.name, this.emoji = '🏠', this.mapBox, List<Shelf>? shelves})
      : id = id ?? newId(),
        shelves = shelves ?? [];

  final String id;
  String name;
  String emoji;
  final List<Shelf> shelves;

  /// Dove sta la stanza sulla mappa della casa. null = posizione automatica.
  MapBox? mapBox;

  int get itemCount => shelves.fold(0, (sum, s) => sum + s.itemCount);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        if (mapBox != null) 'map': mapBox!.toJson(),
        'shelves': shelves.map((s) => s.toJson()).toList(),
      };

  factory Room.fromJson(Map<String, dynamic> j) => Room(
        id: j['id'] as String?,
        name: (j['name'] as String?) ?? '',
        emoji: (j['emoji'] as String?) ?? '🏠',
        mapBox: MapBox.fromJson(j['map']),
        shelves: ((j['shelves'] as List?) ?? [])
            .map((e) => Shelf.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// Dove si trova un oggetto: serve per la ricerca e per il "Faro".
class ItemLocation {
  const ItemLocation({
    required this.room,
    required this.shelf,
    required this.level,
    required this.levelIndex,
    required this.item,
  });

  final Room room;
  final Shelf shelf;
  final Level level;
  final int levelIndex;
  final Item item;

  int get levelNumber => shelf.levelNumber(levelIndex);

  /// Posto (1 = il primo a sinistra).
  int get positionNumber => level.positionOf(item.id) + 1;
}

/// Riferimento a un piano con la sua posizione.
class LevelRef {
  const LevelRef({
    required this.room,
    required this.shelf,
    required this.level,
    required this.levelIndex,
  });

  final Room room;
  final Shelf shelf;
  final Level level;
  final int levelIndex;

  int get levelNumber => shelf.levelNumber(levelIndex);
}
