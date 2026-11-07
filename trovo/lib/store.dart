import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
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
      } catch (_) {}
    }
    if (store.rooms.isEmpty) {
      store.rooms.add(Room(name: defaultRoomName, emoji: '🥫'));
    }
    return store;
  }

  /// Solo per i test: uno store in memoria.
  @visibleForTesting
  factory PantryStore.memory({List<Room>? rooms}) {
    final s = PantryStore._(null);
    if (rooms != null) s.rooms.addAll(rooms);
    if (s.rooms.isEmpty) s.rooms.add(Room(name: 'Dispensa', emoji: '🥫'));
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
        'version': 1,
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

  Room addRoom(String name, String emoji) {
    final room = Room(name: name.trim(), emoji: emoji);
    rooms.add(room);
    _selectedRoomId = room.id;
    _changed();
    return room;
  }

  void updateRoom(Room room, {String? name, String? emoji}) {
    if (name != null && name.trim().isNotEmpty) room.name = name.trim();
    if (emoji != null) room.emoji = emoji;
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
    bool numberFromTop = true,
  }) {
    final shelf = Shelf(name: name.trim(), colorIndex: colorIndex, numberFromTop: numberFromTop);
    for (var i = 0; i < levelCount; i++) {
      // Il colore segue il numero del piano: piano 1 = primo colore.
      final number = numberFromTop ? i + 1 : levelCount - i;
      shelf.levels.add(Level(colorIndex: number - 1));
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
    final level = Level(colorIndex: shelf.levels.length);
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

  // ───────────────────────── Oggetti

  void addItem(Level level, Item item) {
    level.items.add(item);
    _changed();
  }

  void updateItem(Item item, {String? name, String? emoji, int? quantity, String? note}) {
    if (name != null && name.trim().isNotEmpty) item.name = name.trim();
    if (emoji != null) item.emoji = emoji;
    if (quantity != null) item.quantity = quantity.clamp(1, 999);
    if (note != null) item.note = note.trim();
    _changed();
  }

  /// Restituisce la posizione, così si può annullare.
  int removeItem(Level level, Item item) {
    final index = level.items.indexOf(item);
    if (index >= 0) {
      level.items.removeAt(index);
      _changed();
    }
    return index;
  }

  void insertItem(Level level, Item item, int index) {
    level.items.insert(index.clamp(0, level.items.length), item);
    _changed();
  }

  void moveItem(Item item, Level from, Level to) {
    if (from == to) return;
    from.items.remove(item);
    to.items.add(item);
    _changed();
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
