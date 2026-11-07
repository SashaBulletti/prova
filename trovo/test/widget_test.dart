import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trovo/app.dart';
import 'package:trovo/emoji_guess.dart';
import 'package:trovo/models.dart';
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
}
