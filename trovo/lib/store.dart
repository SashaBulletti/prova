import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'scan_codes.dart';
import 'search.dart';

/// Tutti i dati dell'app. Restano solo sul telefono.
class PantryStore extends ChangeNotifier {
  PantryStore._(this._prefs);

  static const _dataKey = 'trovo.data.v1';
  static const _settingsKey = 'trovo.settings.v1';

  final SharedPreferences? _prefs;
  Timer? _saveTimer;

  final List<Room> rooms = [];
  String? _selectedRoomId;

  /// null = lingua del telefono.
  String? localeCode;
  bool speakResults = true;
  bool keepAdding = false;

  /// "Vetro solido": niente trasparenze, per chi si distrae con lo sfondo.
  bool solidGlass = false;

  static Future<PantryStore> load({required String defaultRoomName}) async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('Trovo: salvataggio non disponibile ($e)');
    }
    final store = PantryStore._(prefs);
    final raw = prefs?.getString(_dataKey);
    if (raw != null) {
      try {
        store._readData(jsonDecode(raw) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Trovo: dati non leggibili ($e)');
      }
    }
    final settings = prefs?.getString(_settingsKey);
    if (settings != null) {
      try {
        final s = jsonDecode(settings) as Map<String, dynamic>;
        store.localeCode = s['locale'] as String?;
        store.speakResults = (s['speakResults'] as bool?) ?? true;
        store.keepAdding = (s['keepAdding'] as bool?) ?? false;
        store.solidGlass = (s['solidGlass'] as bool?) ?? false;
      } catch (_) {}
    }
    if (store.rooms.isEmpty) {
      store.rooms.add(Room(name: defaultRoomName, icon: 'pantry'));
    }
    return store;
  }

  /// Solo per i test: uno store in memoria.
  @visibleForTesting
  factory PantryStore.memory({List<Room>? rooms}) {
    final s = PantryStore._(null);
    if (rooms != null) s.rooms.addAll(rooms);
    if (s.rooms.isEmpty) s.rooms.add(Room(name: 'Dispensa', icon: 'pantry'));
    return s;
  }

  void _readData(Map<String, dynamic> data) {
    rooms
      ..clear()
      ..addAll(((data['rooms'] as List?) ?? [])
          .map((e) => Room.fromJson(Map<String, dynamic>.from(e as Map))));
    _selectedRoomId = data['selectedRoomId'] as String?;
  }

  Map<String, dynamic> _dataJson() => {
        'app': 'trovo',
        'version': 2,
        'selectedRoomId': _selectedRoomId,
        'rooms': rooms.map((r) => r.toJson()).toList(),
      };

  void _changed() {
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), saveNow);
  }

  Future<void> saveNow() async {
    _saveTimer?.cancel();
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_dataKey, jsonEncode(_dataJson()));
    await prefs.setString(
      _settingsKey,
      jsonEncode({
        'locale': localeCode,
        'speakResults': speakResults,
        'keepAdding': keepAdding,
        'solidGlass': solidGlass,
      }),
    );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  // ───────────────────────── Stanze

  Room get selectedRoom =>
      rooms.firstWhere((r) => r.id == _selectedRoomId, orElse: () => rooms.first);

  void selectRoom(Room room) {
    _selectedRoomId = room.id;
    _changed();
  }

  Room addRoom(String name, String icon) {
    final room = Room(name: name.trim(), icon: icon);
    rooms.add(room);
    _selectedRoomId = room.id;
    _changed();
    return room;
  }

  void updateRoom(Room room, {String? name, String? icon}) {
    if (name != null && name.trim().isNotEmpty) room.name = name.trim();
    if (icon != null) room.icon = icon;
    _changed();
  }

  bool deleteRoom(Room room) {
    if (rooms.length <= 1) return false;
    rooms.remove(room);
    if (_selectedRoomId == room.id) _selectedRoomId = rooms.first.id;
    _changed();
    return true;
  }

  // ───────────────────────── Scaffali

  Shelf addShelf(
    Room room, {
    required String name,
    required int colorIndex,
    required int levelCount,
    int slotsPerLevel = Level.defaultSlots,
    bool numberFromTop = true,
  }) {
    final shelf = Shelf(name: name.trim(), colorIndex: colorIndex, numberFromTop: numberFromTop);
    for (var i = 0; i < levelCount; i++) {
      // Il colore segue il numero del piano: piano 1 = primo colore.
      final number = numberFromTop ? i + 1 : levelCount - i;
      shelf.levels.add(Level(colorIndex: number - 1, slotCount: slotsPerLevel));
    }
    room.shelves.add(shelf);
    _changed();
    return shelf;
  }

  void updateShelf(Shelf shelf, {String? name, int? colorIndex, bool? numberFromTop}) {
    if (name != null && name.trim().isNotEmpty) shelf.name = name.trim();
    if (colorIndex != null) shelf.colorIndex = colorIndex;
    if (numberFromTop != null) shelf.numberFromTop = numberFromTop;
    _changed();
  }

  void deleteShelf(Room room, Shelf shelf) {
    room.shelves.remove(shelf);
    _changed();
  }

  void moveShelf(Room room, int from, int to) {
    if (from == to || from < 0 || from >= room.shelves.length) return;
    final shelf = room.shelves.removeAt(from);
    room.shelves.insert(to.clamp(0, room.shelves.length), shelf);
    _changed();
  }

  int nextShelfColor(Room room) {
    final used = room.shelves.map((s) => s.colorIndex).toSet();
    for (var i = 0; i < 8; i++) {
      if (!used.contains(i)) return i;
    }
    return room.shelves.length % 8;
  }

  // ───────────────────────── Piani

  /// Il nuovo piano prende sempre il numero successivo.
  /// Restituisce la posizione (dall'alto) dove è stato messo.
  int addLevel(Shelf shelf) {
    // Stessi posti degli altri piani dello scaffale.
    final slots = shelf.levels.isEmpty ? Level.defaultSlots : shelf.levels.last.slotCount;
    final level = Level(colorIndex: shelf.levels.length, slotCount: slots);
    final index = shelf.numberFromTop ? shelf.levels.length : 0;
    shelf.levels.insert(index, level);
    _changed();
    return index;
  }

  void deleteLevel(Shelf shelf, Level level) {
    shelf.levels.remove(level);
    _changed();
  }

  void setLevelPhoto(Level level, String? path) {
    level.photoPath = path;
    _changed();
  }

  // ───────────────────────── Posti

  /// Aggiunge un posto libero in fondo al piano (a destra).
  void addSlot(Level level) {
    level.slots.add(null);
    _changed();
  }

  /// Toglie un posto libero. I posti a destra scorrono di uno.
  bool removeSlot(Level level, int pos) {
    if (pos < 0 || pos >= level.slots.length || level.slots[pos] != null) return false;
    if (level.slots.length <= 1) return false;
    level.slots.removeAt(pos);
    _changed();
    return true;
  }

  /// Quanti posti occupa l'oggetto. Si allarga verso destra (poi sinistra)
  /// solo nei posti liberi accanto. false se non c'è spazio.
  bool setSpan(Level level, Item item, int span) {
    final positions = level.positionsOf(item.id);
    if (positions.isEmpty || span < 1) return false;
    final current = positions.length;
    if (span == current) return true;
    if (span < current) {
      // Libera i posti in fondo a destra.
      for (final p in positions.sublist(span)) {
        level.slots[p] = null;
      }
      _changed();
      return true;
    }
    var need = span - current;
    var right = positions.last + 1;
    var left = positions.first - 1;
    final toTake = <int>[];
    while (need > 0 && right < level.slots.length && level.slots[right] == null) {
      toTake.add(right++);
      need--;
    }
    while (need > 0 && left >= 0 && level.slots[left] == null) {
      toTake.add(left--);
      need--;
    }
    if (need > 0) return false;
    for (final p in toTake) {
      level.slots[p] = item.id;
    }
    _changed();
    return true;
  }

  // ───────────────────────── Oggetti

  /// Mette un oggetto nuovo sul piano. Se [position] è libero lo mette lì,
  /// altrimenti nel primo posto libero (o in un posto nuovo in fondo).
  int addItem(Level level, Item item, {int? position}) {
    level.items.add(item);
    var pos = position ?? -1;
    if (pos < 0 || pos >= level.slots.length || level.slots[pos] != null) {
      pos = level.slots.indexOf(null);
    }
    if (pos < 0) {
      level.slots.add(item.id);
      pos = level.slots.length - 1;
    } else {
      level.slots[pos] = item.id;
    }
    _changed();
    return pos;
  }

  void updateItem(Item item, {String? name, String? emoji, int? quantity, String? note, String? barcode}) {
    if (name != null && name.trim().isNotEmpty) item.name = name.trim();
    if (emoji != null) item.emoji = emoji;
    if (quantity != null) item.quantity = quantity.clamp(1, 999);
    if (note != null) item.note = note.trim();
    if (barcode != null) item.barcode = barcode.isEmpty ? null : barcode;
    _changed();
  }

  /// "Finito": l'oggetto sparisce ma i suoi posti restano liberi.
  /// Restituisce i posti che occupava, così si può annullare.
  List<int> removeItem(Level level, Item item) {
    final positions = level.positionsOf(item.id);
    level.items.remove(item);
    for (final p in positions) {
      level.slots[p] = null;
    }
    _changed();
    return positions;
  }

  /// Annulla "Finito": rimette l'oggetto nei suoi posti, se sono ancora liberi.
  void restoreItem(Level level, Item item, List<int> positions) {
    level.items.add(item);
    var placed = false;
    for (final p in positions) {
      if (p < level.slots.length && level.slots[p] == null) {
        level.slots[p] = item.id;
        placed = true;
      }
    }
    if (!placed) level.normalize();
    _changed();
  }

  /// Sposta un oggetto (con tutti i suoi posti) al posto [to] del piano [toLevel].
  /// Se lì c'è un altro oggetto della stessa larghezza, si scambiano.
  /// false se non c'è spazio.
  bool moveItemTo(Item item, Level fromLevel, Level toLevel, int to, {bool dryRun = false}) {
    final from = fromLevel.positionsOf(item.id);
    if (from.isEmpty) return false;
    final span = from.length;
    if (to < 0) return false;
    // Se lo lasci verso la fine, l'oggetto si appoggia all'ultimo posto.
    if (to + span > toLevel.slots.length) to = toLevel.slots.length - span;
    if (to < 0) return false;
    final target = [for (var i = to; i < to + span; i++) i];
    final sameLevel = identical(fromLevel, toLevel);

    final occupants = <String>{
      for (final p in target)
        if (toLevel.slots[p] != null && !(sameLevel && toLevel.slots[p] == item.id)) toLevel.slots[p]!,
    };

    if (occupants.isEmpty) {
      if (dryRun) return true;
      for (final p in from) {
        fromLevel.slots[p] = null;
      }
      if (!sameLevel) {
        fromLevel.items.remove(item);
        toLevel.items.add(item);
      }
      for (final p in target) {
        toLevel.slots[p] = item.id;
      }
      _changed();
      return true;
    }

    // Scambio con un solo oggetto della stessa larghezza.
    if (occupants.length == 1) {
      final otherId = occupants.first;
      final otherPos = toLevel.positionsOf(otherId);
      final other = toLevel.itemById(otherId);
      if (other != null && otherPos.length == span && otherPos.first == to) {
        if (dryRun) return true;
        for (final p in from) {
          fromLevel.slots[p] = otherId;
        }
        for (final p in target) {
          toLevel.slots[p] = item.id;
        }
        if (!sameLevel) {
          fromLevel.items.remove(item);
          toLevel.items.remove(other);
          toLevel.items.add(item);
          fromLevel.items.add(other);
        }
        _changed();
        return true;
      }
    }
    return false;
  }

  /// Sposta in un altro piano, nel primo posto libero.
  void moveItem(Item item, Level from, Level to) {
    if (identical(from, to)) return;
    final span = from.spanOf(item.id).clamp(1, 999);
    for (final p in from.positionsOf(item.id)) {
      from.slots[p] = null;
    }
    from.items.remove(item);
    to.items.add(item);
    var placed = 0;
    for (var i = 0; i < to.slots.length && placed < span; i++) {
      if (to.slots[i] == null) {
        to.slots[i] = item.id;
        placed++;
      }
    }
    while (placed < span) {
      to.slots.add(item.id);
      placed++;
    }
    _changed();
  }

  /// Applica le modifiche lette da una foto.
  /// Prima toglie gli oggetti che si spostano, poi li rimette al posto giusto.
  /// Se un posto è occupato da un oggetto che non si sposta, quello va nel primo posto libero.
  void applyPhotoMoves(List<PhotoMove> moves) {
    if (moves.isEmpty) return;
    final moving = moves.map((m) => m.item.id).toSet();
    for (final m in moves) {
      for (final p in m.fromLevel.positionsOf(m.item.id)) {
        m.fromLevel.slots[p] = null;
      }
      m.fromLevel.items.remove(m.item);
    }
    final displaced = <({Level level, Item item})>[];
    for (final m in moves) {
      final level = m.toLevel;
      while (level.slots.length < m.start + m.span) {
        level.slots.add(null);
      }
      for (var p = m.start; p < m.start + m.span; p++) {
        final other = level.slots[p];
        if (other != null && !moving.contains(other)) {
          final item = level.itemById(other);
          for (final q in level.positionsOf(other)) {
            level.slots[q] = null;
          }
          if (item != null) {
            level.items.remove(item);
            displaced.add((level: level, item: item));
          }
        }
        level.slots[p] = m.item.id;
      }
      level.items.add(m.item);
    }
    for (final d in displaced) {
      d.level.items.add(d.item);
      d.level.normalize();
    }
    _changed();
  }

  ({Level level, Item item})? findItemWithLevel(String itemId) {
    for (final ref in allLevels()) {
      final item = ref.level.itemById(itemId);
      if (item != null) return (level: ref.level, item: item);
    }
    return null;
  }

  Item? findByBarcode(String code) {
    for (final ref in allLevels()) {
      for (final item in ref.level.items) {
        if (item.barcode == code) return item;
      }
    }
    return null;
  }

  // ───────────────────────── Trovare le cose

  List<SearchResult> search(String query) => searchItems(rooms, query);

  ItemLocation? locate(String itemId) {
    for (final room in rooms) {
      for (final shelf in room.shelves) {
        for (var li = 0; li < shelf.levels.length; li++) {
          final level = shelf.levels[li];
          for (final item in level.items) {
            if (item.id == itemId) {
              return ItemLocation(
                  room: room, shelf: shelf, level: level, levelIndex: li, item: item);
            }
          }
        }
      }
    }
    return null;
  }

  LevelRef? findLevel(String levelId) {
    for (final ref in allLevels()) {
      if (ref.level.id == levelId) return ref;
    }
    return null;
  }

  List<LevelRef> allLevels() => [
        for (final room in rooms)
          for (final shelf in room.shelves)
            for (var li = 0; li < shelf.levels.length; li++)
              LevelRef(room: room, shelf: shelf, level: shelf.levels[li], levelIndex: li),
      ];

  Room roomOf(Shelf shelf) =>
      rooms.firstWhere((r) => r.shelves.contains(shelf), orElse: () => rooms.first);

  List<ItemLocation> recentItems({int limit = 8}) {
    final all = <ItemLocation>[];
    for (final ref in allLevels()) {
      for (final item in ref.level.items) {
        all.add(ItemLocation(
            room: ref.room, shelf: ref.shelf, level: ref.level, levelIndex: ref.levelIndex, item: item));
      }
    }
    all.sort((a, b) => b.item.addedAt.compareTo(a.item.addedAt));
    return all.take(limit).toList();
  }

  // ───────────────────────── Impostazioni

  void setLocale(String? code) {
    localeCode = code;
    _changed();
  }

  void setSpeakResults(bool value) {
    speakResults = value;
    _changed();
  }

  void setSolidGlass(bool value) {
    solidGlass = value;
    _changed();
  }

  void setKeepAdding(bool value) {
    keepAdding = value;
    _changed();
  }

  // ───────────────────────── Backup

  String exportJson() {
    final data = _dataJson()..['exportedAt'] = DateTime.now().toIso8601String();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// false se il file non è un backup valido.
  bool importJson(String raw) {
    try {
      final data = jsonDecode(raw);
      if (data is! Map || data['app'] != 'trovo' || data['rooms'] is! List) return false;
      final parsed = (data['rooms'] as List)
          .map((e) => Room.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (parsed.isEmpty) return false;
      rooms
        ..clear()
        ..addAll(parsed);
      _selectedRoomId = data['selectedRoomId'] as String?;
      _changed();
      return true;
    } catch (_) {
      return false;
    }
  }
}
