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
    int? addedAt,
  })  : id = id ?? newId(),
        addedAt = addedAt ?? DateTime.now().millisecondsSinceEpoch;

  final String id;
  String name;
  String emoji;
  int quantity;
  String note;
  int addedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'quantity': quantity,
        'note': note,
        'addedAt': addedAt,
      };

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        id: j['id'] as String?,
        name: (j['name'] as String?) ?? '',
        emoji: (j['emoji'] as String?) ?? '📦',
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        note: (j['note'] as String?) ?? '',
        addedAt: (j['addedAt'] as num?)?.toInt(),
      );
}

class Level {
  Level({String? id, required this.colorIndex, this.photoPath, List<Item>? items})
      : id = id ?? newId(),
        items = items ?? [];

  final String id;
  int colorIndex;
  String? photoPath;
  final List<Item> items;

  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);

  Map<String, dynamic> toJson() => {
        'id': id,
        'colorIndex': colorIndex,
        'photoPath': photoPath,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory Level.fromJson(Map<String, dynamic> j) => Level(
        id: j['id'] as String?,
        colorIndex: (j['colorIndex'] as num?)?.toInt() ?? 0,
        photoPath: j['photoPath'] as String?,
        items: ((j['items'] as List?) ?? [])
            .map((e) => Item.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class Shelf {
  Shelf({
    String? id,
    required this.name,
    required this.colorIndex,
    this.numberFromTop = true,
    List<Level>? levels,
  })  : id = id ?? newId(),
        levels = levels ?? [];

  final String id;
  String name;
  int colorIndex;

  /// true: il piano 1 è quello in alto. false: il piano 1 è quello in basso.
  bool numberFromTop;

  /// I piani sono sempre salvati dall'alto verso il basso, come li vedi.
  final List<Level> levels;

  int levelNumber(int index) =>
      numberFromTop ? index + 1 : levels.length - index;

  int get itemCount => levels.fold(0, (sum, l) => sum + l.items.length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorIndex': colorIndex,
        'numberFromTop': numberFromTop,
        'levels': levels.map((l) => l.toJson()).toList(),
      };

  factory Shelf.fromJson(Map<String, dynamic> j) => Shelf(
        id: j['id'] as String?,
        name: (j['name'] as String?) ?? '',
        colorIndex: (j['colorIndex'] as num?)?.toInt() ?? 0,
        numberFromTop: (j['numberFromTop'] as bool?) ?? true,
        levels: ((j['levels'] as List?) ?? [])
            .map((e) => Level.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class Room {
  Room({String? id, required this.name, this.emoji = '🏠', List<Shelf>? shelves})
      : id = id ?? newId(),
        shelves = shelves ?? [];

  final String id;
  String name;
  String emoji;
  final List<Shelf> shelves;

  int get itemCount => shelves.fold(0, (sum, s) => sum + s.itemCount);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'shelves': shelves.map((s) => s.toJson()).toList(),
      };

  factory Room.fromJson(Map<String, dynamic> j) => Room(
        id: j['id'] as String?,
        name: (j['name'] as String?) ?? '',
        emoji: (j['emoji'] as String?) ?? '🏠',
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
