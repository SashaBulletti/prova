import 'dart:math' as math;

import 'models.dart';

/// Ricerca "gentile": capisce gli errori di battitura, gli accenti,
/// il plurale e alcuni sinonimi. Non serve nessuna AI.

const _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n',
};

String normalize(String input) {
  final lower = input.toLowerCase();
  final buf = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final mapped = _accents[ch] ?? ch;
    final code = mapped.codeUnitAt(0);
    final isAlnum = (code >= 97 && code <= 122) || (code >= 48 && code <= 57);
    buf.write(isAlnum ? mapped : ' ');
  }
  return buf.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Parole "di riempimento" da togliere quando si cerca a voce:
/// "dov'è la passata?" → "passata".
const _stopWords = {
  // italiano
  'dov', 'dove', 'e', 'sono', 'sta', 'stanno', 'si', 'trova', 'trovano',
  'il', 'lo', 'la', 'i', 'gli', 'le', 'l', 'un', 'uno', 'una',
  'di', 'del', 'della', 'dello', 'dei', 'degli', 'delle', 'mio', 'mia',
  'miei', 'mie', 'ho', 'messo', 'messa', 'messi', 'messe', 'cerca', 'cercami',
  'trovami', 'trovare', 'cercare', 'c', 'ce', 'ci', 'che', 'per', 'favore',
  'quale', 'qual', 'in', 'nel', 'nella', 'a', 'al', 'alla',
  // inglese
  'where', 'is', 'are', 'the', 'my', 'an', 'did', 'put', 'find',
  'search', 'for', 'some', 'please', 'whats', 'what', 'of',
};

String cleanVoiceQuery(String spoken) {
  final words = normalize(spoken).split(' ');
  final kept = words.where((w) => w.isNotEmpty && !_stopWords.contains(w));
  final result = kept.join(' ');
  return result.isEmpty ? normalize(spoken) : result;
}

/// Gruppi di sinonimi: se cerchi una parola, trovi anche le altre.
const _synonymGroups = <List<String>>[
  ['passata', 'pomodoro', 'pomodori', 'pelati', 'salsa', 'sugo', 'tomato', 'tomatoes', 'sauce'],
  ['pasta', 'spaghetti', 'penne', 'fusilli', 'rigatoni', 'maccheroni', 'farfalle', 'linguine', 'tagliatelle', 'noodles'],
  ['riso', 'rice', 'risotto', 'basmati', 'carnaroli', 'arborio'],
  ['olio', 'oil', 'extravergine'],
  ['aceto', 'vinegar', 'balsamico'],
  ['tonno', 'tuna'],
  ['latte', 'milk'],
  ['caffe', 'coffee', 'cialde', 'capsule'],
  ['biscotti', 'cookies', 'biscuits', 'frollini'],
  ['legumi', 'fagioli', 'ceci', 'lenticchie', 'piselli', 'beans', 'chickpeas', 'lentils'],
  ['farina', 'flour'],
  ['zucchero', 'sugar'],
  ['sale', 'salt'],
  ['acqua', 'water'],
  ['vino', 'wine'],
  ['birra', 'beer'],
  ['detersivo', 'detergente', 'sapone', 'detergent', 'soap'],
  ['carta', 'scottex', 'tovaglioli', 'paper', 'towels'],
  ['batterie', 'pile', 'batteries'],
  ['lampadina', 'lampadine', 'bulb', 'bulbs'],
  ['cereali', 'cereals', 'muesli', 'cornflakes'],
  ['marmellata', 'confettura', 'jam'],
  ['cioccolato', 'cioccolata', 'chocolate', 'nutella'],
  ['crackers', 'cracker', 'grissini', 'fette', 'biscottate'],
  ['te', 'tea', 'tisana', 'infuso'],
  ['spezie', 'spices', 'pepe', 'origano', 'paprika', 'curry'],
];

final Map<String, Set<String>> _synonymIndex = () {
  final map = <String, Set<String>>{};
  for (final group in _synonymGroups) {
    final set = group.map(_stem).toSet();
    for (final w in group) {
      map.putIfAbsent(_stem(w), () => <String>{}).addAll(set);
    }
  }
  return map;
}();

/// Toglie le desinenze più comuni (passata/passate, pomodoro/pomodori, tomato/tomatoes).
String _stem(String w) {
  var s = w;
  if (s.length > 4 && s.endsWith('es')) s = s.substring(0, s.length - 2);
  if (s.length > 3 && RegExp(r'[aeiouhs]$').hasMatch(s)) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

int _levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  var curr = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    curr[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      final ins = curr[j - 1] + 1;
      final del = prev[j] + 1;
      final sub = prev[j - 1] + cost;
      curr[j] = ins < del ? (ins < sub ? ins : sub) : (del < sub ? del : sub);
    }
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[b.length];
}

/// Quanto si somigliano due parole (da 0 a 1).
double _wordScore(String query, String word) {
  if (word == query) return 1.0;
  if (word.startsWith(query)) return query.length >= 2 ? 0.92 : 0.6;
  final qs = _stem(query);
  final ws = _stem(word);
  if (qs == ws) return 0.95;
  if (ws.startsWith(qs) && qs.length >= 3) return 0.85;
  if (word.contains(query) && query.length >= 3) return 0.75;
  // Tolleranza agli errori: "pasatta" ≈ "passata".
  if (query.length < 3 || word.length < 3) return 0;
  final allowed = query.length <= 4 ? 1 : (query.length <= 7 ? 2 : 3);
  final dist = math.min(_levenshtein(query, word), _levenshtein(qs, ws));
  if (dist > allowed) return 0;
  final maxLen = math.max(query.length, word.length);
  final sim = 1 - dist / maxLen;
  // Le coppie di lettere in comune distinguono "passata" da "pasta".
  return 0.5 + 0.35 * (sim + _dice(query, word)) / 2;
}

double _dice(String a, String b) {
  if (a.length < 2 || b.length < 2) return 0;
  final pairs = <String, int>{};
  for (var i = 0; i < a.length - 1; i++) {
    final p = a.substring(i, i + 2);
    pairs[p] = (pairs[p] ?? 0) + 1;
  }
  var common = 0;
  for (var i = 0; i < b.length - 1; i++) {
    final p = b.substring(i, i + 2);
    final n = pairs[p] ?? 0;
    if (n > 0) {
      common++;
      pairs[p] = n - 1;
    }
  }
  return 2 * common / (a.length - 1 + b.length - 1);
}

double scoreText(String query, String text) {
  final q = normalize(query);
  final t = normalize(text);
  if (q.isEmpty || t.isEmpty) return 0;
  if (t == q) return 1.0;
  final qWords = q.split(' ');
  final tWords = t.split(' ');
  var total = 0.0;
  for (final qw in qWords) {
    var best = 0.0;
    final synonyms = _synonymIndex[_stem(qw)];
    for (final tw in tWords) {
      var s = _wordScore(qw, tw);
      // Un sinonimo vale più di una parola solo "somigliante".
      if (s < 0.8 && synonyms != null && synonyms.contains(_stem(tw))) {
        s = 0.8;
      }
      if (s > best) best = s;
    }
    total += best;
  }
  return total / qWords.length;
}

class SearchResult {
  const SearchResult(this.location, this.score);
  final ItemLocation location;
  final double score;
}

List<SearchResult> searchItems(List<Room> rooms, String query, {double minScore = 0.5}) {
  if (normalize(query).isEmpty) return const [];
  final results = <SearchResult>[];
  for (final room in rooms) {
    for (final shelf in room.shelves) {
      for (var li = 0; li < shelf.levels.length; li++) {
        final level = shelf.levels[li];
        for (final item in level.items) {
          var score = scoreText(query, item.name);
          if (item.note.isNotEmpty) {
            final noteScore = scoreText(query, item.note) * 0.8;
            if (noteScore > score) score = noteScore;
          }
          if (score >= minScore) {
            results.add(SearchResult(
              ItemLocation(room: room, shelf: shelf, level: level, levelIndex: li, item: item),
              score,
            ));
          }
        }
      }
    }
  }
  results.sort((a, b) {
    final c = b.score.compareTo(a.score);
    if (c != 0) return c;
    return a.location.item.name.length.compareTo(b.location.item.name.length);
  });
  return results;
}
