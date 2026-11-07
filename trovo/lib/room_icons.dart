import 'package:flutter/widgets.dart';
import 'icons.dart';

/// Icone a linea per le stanze (le emoji restano solo sugli oggetti).
const roomIconKeys = <String>[
  'pantry',
  'kitchen',
  'house',
  'garage',
  'cellar',
  'bedroom',
  'bathroom',
  'living',
  'laundry',
  'tools',
  'freezer',
  'storage',
  'kids',
  'garden',
];

IconData roomIcon(String key) => switch (normalizeRoomIcon(key)) {
      'pantry' => PIcons.jar,
      'kitchen' => PIcons.cookingPot,
      'garage' => PIcons.car,
      'cellar' => PIcons.wine,
      'bedroom' => PIcons.bed,
      'bathroom' => PIcons.bathtub,
      'living' => PIcons.couch,
      'laundry' => PIcons.washingMachine,
      'tools' => PIcons.toolbox,
      'freezer' => PIcons.snowflake,
      'storage' => PIcons.package,
      'kids' => PIcons.baby,
      'garden' => PIcons.plant,
      _ => PIcons.house,
    };

/// Le stanze della versione 1 avevano un'emoji: la trasformo nell'icona giusta.
String normalizeRoomIcon(String value) {
  if (roomIconKeys.contains(value)) return value;
  return switch (value) {
    '🥫' => 'pantry',
    '🍳' => 'kitchen',
    '🚗' => 'garage',
    '🍷' => 'cellar',
    '🛏️' => 'bedroom',
    '🛁' => 'bathroom',
    '🧹' => 'laundry',
    '🧰' => 'tools',
    '❄️' => 'freezer',
    '📦' => 'storage',
    '🌱' => 'garden',
    _ => 'house',
  };
}
