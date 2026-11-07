import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trovo/app.dart';
import 'package:trovo/emoji_guess.dart';
import 'package:trovo/models.dart';
import 'package:trovo/scan_codes.dart';
import 'package:trovo/search.dart';
import 'package:trovo/store.dart';

PantryStore _sampleStore() {
  final store = PantryStore.memory();
  final room = store.rooms.first;
  final shelf = store.addShelf(room, name: 'Scaffale Blu', colorIndex: 0, levelCount: 4);
  store.addItem(shelf.levels[2], Item(name: 'Passata di pomodoro', emoji: '🍅', quantity: 3));
  store.addItem(shelf.levels[0], Item(name: 'Spaghetti', emoji: '🍝'));
  store.addItem(shelf.levels[1], Item(name: 'Pile AA', emoji: '🔋'));
  store.addItem(shelf.levels[3], Item(name: 'Pasta', emoji: '🍝'));
  return store;
}

void main() {
  group('Ricerca', () {
    final store = _sampleStore();

    test('trova con errori di battitura', () {
      expect(store.search('pasatta').first.location.item.name, 'Passata di pomodoro');
      expect(store.search('spagetti').first.location.item.name, 'Spaghetti');
      expect(store.search('pomodri').first.location.item.name, 'Passata di pomodoro');
    });

    test('trova con sinonimi e plurale', () {
      expect(store.search('pomodori').first.location.item.name, 'Passata di pomodoro');
      expect(store.search('pasta').first.location.item.name, 'Pasta');
      expect(store.search('pasta')[1].location.item.name, 'Spaghetti');
      expect(store.search('batterie').first.location.item.name, 'Pile AA');
    });

    test('non trova cose che non ci sono', () {
      expect(store.search('cioccolato'), isEmpty);
    });

    test('pulisce le frasi dette a voce', () {
      expect(cleanVoiceQuery("Dov'è la passata?"), 'passata');
      expect(cleanVoiceQuery('Where are my batteries'), 'batteries');
    });

    test('il piano giusto ha il numero giusto', () {
      final loc = store.search('passata').first.location;
      expect(loc.levelNumber, 3);
      expect(loc.shelf.name, 'Scaffale Blu');
    });
  });

  group('Scaffali e piani', () {
    test('numerazione dal basso', () {
      final store = PantryStore.memory();
      final shelf = store.addShelf(store.rooms.first, name: 'X', colorIndex: 1, levelCount: 5, numberFromTop: false);
      expect(shelf.levelNumber(0), 5);
      expect(shelf.levelNumber(4), 1);
      // Il nuovo piano prende il numero 6 e va in cima.
      final idx = store.addLevel(shelf);
      expect(idx, 0);
      expect(shelf.levelNumber(0), 6);
    });

    test('backup: esporta e ripristina', () {
      final store = _sampleStore();
      final json = store.exportJson();
      final other = PantryStore.memory();
      expect(other.importJson(json), isTrue);
      expect(other.search('passata').first.location.item.quantity, 3);
      expect(other.importJson('{"ciao": 1}'), isFalse);
    });
  });

  test('emoji indovinate dal nome', () {
    expect(guessEmoji('Passata'), '🍅');
    expect(guessEmoji('Penne rigate'), '🍝');
    expect(guessEmoji('Tonno'), '🐟');
    expect(guessEmoji('Cosa strana'), '📦');
  });

  testWidgets('la Home mostra stanza e scaffale', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = _sampleStore();
    await tester.pumpWidget(TrovoApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Trovo'), findsOneWidget);
    expect(find.text('Scaffale Blu'), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsWidgets);
  });

  group('Posti', () {
    test('uno scaffale nuovo ha 5 posti per piano, tutti liberi', () {
      final store = PantryStore.memory();
      final shelf = store.addShelf(store.rooms.first, name: 'A', colorIndex: 0, levelCount: 5);
      for (final l in shelf.levels) {
        expect(l.slotCount, 5);
        expect(l.freeCount, 5);
      }
    });

    test('metti una cosa in un posto preciso, il + aggiunge un posto', () {
      final store = PantryStore.memory();
      final level = store.addShelf(store.rooms.first, name: 'A', colorIndex: 0, levelCount: 1).levels.first;
      final pomarola = Item(name: 'Pomarola', quantity: 6);
      expect(store.addItem(level, pomarola, position: 4), 4);
      expect(level.slots, [null, null, null, null, pomarola.id]);
      store.addSlot(level);
      expect(level.slotCount, 6);
    });

    test('quando una cosa finisce il suo posto resta libero', () {
      final store = PantryStore.memory();
      final level = store.addShelf(store.rooms.first, name: 'A', colorIndex: 0, levelCount: 1).levels.first;
      final aglio = Item(name: 'Aglio');
      final pasta = Item(name: 'Pasta');
      store.addItem(level, aglio, position: 0);
      store.addItem(level, pasta, position: 1);
      final was = store.removeItem(level, aglio);
      expect(level.slots[0], isNull);
      expect(level.slots[1], pasta.id);
      store.restoreItem(level, aglio, was);
      expect(level.slots[0], aglio.id);
    });

    test('12 pomarole su 2 posti: 6 + 6', () {
      final store = PantryStore.memory();
      final level = store.addShelf(store.rooms.first, name: 'A', colorIndex: 0, levelCount: 1).levels.first;
      final pomarola = Item(name: 'Pomarola', quantity: 12);
      store.addItem(level, pomarola, position: 1);
      expect(store.setSpan(level, pomarola, 2), isTrue);
      expect(level.positionsOf(pomarola.id), [1, 2]);
      expect(level.blocks.where((b) => !b.isEmpty).single.span, 2);
      final ceci = Item(name: 'Ceci');
      store.addItem(level, ceci, position: 3);
      // Non c'è spazio a destra (ceci) ma c'è a sinistra.
      expect(store.setSpan(level, pomarola, 3), isTrue);
      expect(level.positionsOf(pomarola.id), [0, 1, 2]);
      expect(store.setSpan(level, pomarola, 5), isFalse);
    });

    test('trascinare: sposta in un posto libero o scambia', () {
      final store = PantryStore.memory();
      final shelf = store.addShelf(store.rooms.first, name: 'A', colorIndex: 0, levelCount: 2);
      final top = shelf.levels[0];
      final bottom = shelf.levels[1];
      final ceci = Item(name: 'Ceci');
      final fagioli = Item(name: 'Fagioli');
      store.addItem(top, ceci, position: 0);
      store.addItem(top, fagioli, position: 1);
      expect(store.moveItemTo(ceci, top, top, 3), isTrue);
      expect(top.slots, [null, fagioli.id, null, ceci.id, null]);
      // Scambio con un oggetto della stessa larghezza.
      expect(store.moveItemTo(ceci, top, top, 1), isTrue);
      expect(top.slots, [null, ceci.id, null, fagioli.id, null]);
      // In un altro piano.
      expect(store.moveItemTo(ceci, top, bottom, 2), isTrue);
      expect(bottom.slots[2], ceci.id);
      expect(top.items.contains(ceci), isFalse);
      expect(bottom.items.contains(ceci), isTrue);
    });

    test('i dati della versione 1 diventano posti da sinistra', () {
      final level = Level.fromJson({
        'id': 'x',
        'colorIndex': 0,
        'items': [
          {'id': 'a', 'name': 'Pomarola'},
          {'id': 'b', 'name': 'Ceci'},
        ],
      });
      expect(level.slots, ['a', 'b', null, null, null]);
    });
  });

  group('Foto con i QR', () {
    test('ogni barattolo va sul posto che ha sotto', () {
      final store = PantryStore.memory();
      final shelf = store.addShelf(store.rooms.first, name: 'A', colorIndex: 0, levelCount: 1);
      final level = shelf.levels.first;
      final pomarola = Item(name: 'Pomarola');
      final ceci = Item(name: 'Ceci');
      store.addItem(level, pomarola, position: 0);
      store.addItem(level, ceci, position: 1);

      // Nella foto: i posti 1..5 sul bordo, la pomarola sopra il posto 5, i ceci sopra il 3.
      Rect at(double x, double y) => Rect.fromCenter(center: Offset(x, y), width: 40, height: 40);
      final codes = [
        for (var p = 1; p <= 5; p++) ScannedCode(TrovoCode.forSlot(level.id, p), at(100.0 * p, 500)),
        ScannedCode(TrovoCode.forItem(pomarola.id), at(505, 300)),
        ScannedCode(TrovoCode.forItem(ceci.id), at(290, 320)),
      ];
      final plan = planFromPhoto(codes, findLevel: (id) => store.findLevel(id)?.level, findItem: store.findItemWithLevel);
      expect(plan.slotCodes, 5);
      expect(plan.moves.length, 2);
      store.applyPhotoMoves(plan.moves);
      expect(level.slots, [null, null, ceci.id, null, pomarola.id]);
    });

    test('i codici si leggono e si riconoscono', () {
      expect(TrovoCode.parse('trovo:p:abc:3')!.position, 3);
      expect(TrovoCode.parse('trovo:i:xyz')!.kind, TrovoCodeKind.item);
      expect(TrovoCode.parse('8001234567890'), isNull);
    });
  });
}
