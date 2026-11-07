import 'search.dart' show normalize;

/// Indovina un'emoji dal nome, così non devi sceglierla tu.
/// "Passata di pomodoro" → 🍅
const _emojiByWord = <String, String>{
  'passat': '🍅', 'pomodor': '🍅', 'pelat': '🍅', 'sug': '🍅', 'salsa': '🍅', 'tomato': '🍅', 'sauce': '🍅', 'ketchup': '🍅',
  'pasta': '🍝', 'spaghett': '🍝', 'penn': '🍝', 'fusill': '🍝', 'rigaton': '🍝', 'maccheron': '🍝', 'farfall': '🍝', 'linguin': '🍝', 'tagliatell': '🍝', 'noodle': '🍜', 'ramen': '🍜',
  'riso': '🍚', 'rice': '🍚', 'basmati': '🍚', 'risott': '🍚',
  'olio': '🫒', 'oil': '🫒', 'oliv': '🫒',
  'acet': '🍶', 'vinegar': '🍶', 'soia': '🍶', 'soy': '🍶',
  'tonn': '🐟', 'tuna': '🐟', 'sgombr': '🐟', 'acciugh': '🐟', 'alic': '🐟', 'sardin': '🐟', 'salmon': '🐟',
  'latt': '🥛', 'milk': '🥛', 'panna': '🥛', 'cream': '🥛',
  'caff': '☕', 'coffee': '☕', 'cialde': '☕', 'capsul': '☕',
  'te': '🍵', 'tea': '🍵', 'tisan': '🍵', 'camomill': '🍵', 'infus': '🍵',
  'biscott': '🍪', 'cookie': '🍪', 'biscuit': '🍪', 'frollin': '🍪', 'wafer': '🍪',
  'fagiol': '🫘', 'cec': '🫘', 'lenticch': '🫘', 'legum': '🫘', 'bean': '🫘', 'chickpea': '🫘', 'lentil': '🫘',
  'pisell': '🫛', 'pea': '🫛',
  'mais': '🌽', 'corn': '🌽',
  'farin': '🌾', 'flour': '🌾',
  'zucchero': '🧂', 'sugar': '🧂', 'sale': '🧂', 'salt': '🧂', 'pepe': '🧂', 'pepper': '🧂',
  'spezi': '🌿', 'spice': '🌿', 'origan': '🌿', 'basilic': '🌿', 'rosmarin': '🌿', 'curry': '🌿', 'paprika': '🌶️', 'peperoncin': '🌶️', 'chili': '🌶️',
  'acqua': '💧', 'water': '💧',
  'vino': '🍷', 'wine': '🍷', 'prosecc': '🍾', 'spumant': '🍾', 'champagne': '🍾',
  'birr': '🍺', 'beer': '🍺',
  'succ': '🧃', 'juice': '🧃', 'bibit': '🥤', 'cola': '🥤', 'aranciata': '🥤', 'soda': '🥤',
  'cereal': '🥣', 'muesli': '🥣', 'granola': '🥣', 'cornflake': '🥣', 'avena': '🥣', 'oat': '🥣',
  'marmellat': '🍯', 'confettur': '🍯', 'jam': '🍯', 'miel': '🍯', 'honey': '🍯',
  'cioccolat': '🍫', 'chocolate': '🍫', 'nutella': '🍫', 'cacao': '🍫', 'cocoa': '🍫',
  'cracker': '🥨', 'grissin': '🥨', 'tarall': '🥨', 'pretzel': '🥨', 'patatin': '🥔', 'chips': '🥔',
  'pane': '🍞', 'bread': '🍞', 'fett': '🍞', 'pancarre': '🍞', 'piadin': '🫓', 'tortill': '🫓',
  'patat': '🥔', 'potato': '🥔', 'cipoll': '🧅', 'onion': '🧅', 'agli': '🧄', 'garlic': '🧄',
  'mela': '🍎', 'mele': '🍎', 'apple': '🍎', 'banan': '🍌', 'aranc': '🍊', 'orange': '🍊', 'limon': '🍋', 'lemon': '🍋',
  'frutta': '🍑', 'fruit': '🍑', 'pesch': '🍑', 'ananas': '🍍', 'pineapple': '🍍',
  'uova': '🥚', 'uovo': '🥚', 'egg': '🥚',
  'formagg': '🧀', 'cheese': '🧀', 'parmigian': '🧀', 'grana': '🧀',
  'carne': '🥫', 'scatolett': '🥫', 'lattin': '🥫', 'can': '🥫', 'zupp': '🥣', 'soup': '🥣', 'brodo': '🥣', 'dado': '🧊',
  'mandorl': '🥜', 'noc': '🌰', 'nut': '🥜', 'arachid': '🥜', 'peanut': '🥜', 'pistacch': '🥜',
  'dolc': '🍬', 'caramell': '🍬', 'candy': '🍬', 'merendin': '🧁', 'torta': '🍰', 'cake': '🍰',
  'gelat': '🍨', 'surgelat': '🧊', 'frozen': '🧊',
  'croccantin': '🐾', 'gatt': '🐱', 'cat': '🐱', 'cane': '🐶', 'cani': '🐶', 'dog': '🐶',
  'detersiv': '🧴', 'detergent': '🧴', 'sapon': '🧼', 'soap': '🧼', 'shampoo': '🧴', 'ammorbident': '🧴', 'candeggin': '🧴', 'bleach': '🧴',
  'spugn': '🧽', 'sponge': '🧽', 'scop': '🧹', 'broom': '🧹',
  'carta': '🧻', 'scottex': '🧻', 'tovagliol': '🧻', 'paper': '🧻', 'towel': '🧻', 'fazzolett': '🧻', 'tissue': '🧻',
  'sacch': '🛍️', 'bag': '🛍️', 'pellicol': '🎞️', 'alluminio': '🎞️', 'foil': '🎞️',
  'batteri': '🔋', 'pile': '🔋', 'battery': '🔋', 'batteries': '🔋',
  'lampadin': '💡', 'bulb': '💡', 'candel': '🕯️', 'candle': '🕯️',
  'attrezz': '🧰', 'tool': '🧰', 'cacciavit': '🪛', 'screwdriver': '🪛', 'martell': '🔨', 'hammer': '🔨', 'vit': '🔩', 'screw': '🔩', 'chiod': '🔩', 'nail': '🔩',
  'nastr': '📼', 'tape': '📼', 'scotch': '📼', 'colla': '🧴', 'glue': '🧴',
  'medicin': '💊', 'farmac': '💊', 'pastigl': '💊', 'medicine': '💊', 'pill': '💊', 'cerott': '🩹', 'plaster': '🩹',
  'piatt': '🍽️', 'plate': '🍽️', 'bicchier': '🥛', 'glass': '🥛', 'posat': '🍴', 'cutlery': '🍴', 'pentol': '🍲', 'pot': '🍲', 'padell': '🍳', 'pan': '🍳',
  'vestit': '👕', 'clothes': '👕', 'scarp': '👟', 'shoe': '👟', 'giocattol': '🧸', 'toy': '🧸', 'libr': '📚', 'book': '📚',
  'cav': '🔌', 'cable': '🔌', 'caricator': '🔌', 'charger': '🔌',
  'vernic': '🎨', 'paint': '🎨', 'pennell': '🖌️', 'brush': '🖌️',
  'natale': '🎄', 'christmas': '🎄', 'addobb': '🎄', 'decoration': '🎄',
  'scatol': '📦', 'box': '📦',
};

String guessEmoji(String name) {
  final n = normalize(name);
  if (n.isEmpty) return '📦';
  final words = n.split(' ');
  // Prima prova parola per parola, poi l'intero nome.
  for (final w in words) {
    String? best;
    var bestLen = 0;
    _emojiByWord.forEach((key, emoji) {
      if (key.contains(' ')) return;
      final match = w == key || (key.length >= 3 && w.startsWith(key));
      if (match && key.length > bestLen) {
        best = emoji;
        bestLen = key.length;
      }
    });
    if (best != null) return best!;
  }
  for (final entry in _emojiByWord.entries) {
    if (entry.key.contains(' ') && n.contains(entry.key)) return entry.value;
  }
  return '📦';
}

/// Emoji che si possono scegliere a mano.
const pickableEmojis = <String>[
  '📦', '🍝', '🍅', '🍚', '🫒', '🐟', '🥫', '🫘', '🌾', '🧂', '🌿', '🍯',
  '🍫', '🍪', '🥨', '🥣', '☕', '🍵', '🥛', '🧃', '🍷', '🍺', '💧', '🍞',
  '🥔', '🧅', '🧄', '🍎', '🍌', '🍋', '🥚', '🧀', '🥜', '🍬', '🧊', '🐱',
  '🐶', '🧴', '🧼', '🧽', '🧹', '🧻', '🛍️', '🔋', '💡', '🧰', '🔩', '💊',
  '🍽️', '🍳', '👕', '🧸', '📚', '🔌', '🎨', '🎄',
];

/// Emoji per le stanze.
const roomEmojis = <String>['🥫', '🏠', '🍳', '🚗', '🍷', '🧹', '🧰', '❄️', '📦', '🛏️', '🛁', '🌱'];
