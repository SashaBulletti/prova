import 'package:flutter/widgets.dart';

/// Tutti i testi dell'app, in italiano e in inglese.
/// Frasi corte e semplici: è un'app pensata anche per chi ha ADHD o dislessia.
class S {
  const S(this.it);

  /// true = italiano, false = inglese.
  final bool it;

  static const supportedLocales = [Locale('it'), Locale('en')];

  static S of(BuildContext context) =>
      Localizations.of<S>(context, S) ?? const S(false);

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  String get localeTag => it ? 'it-IT' : 'en-US';

  String _t(String itText, String enText) => it ? itText : enText;

  // Generale
  String get appName => 'Trovo';
  String get tagline => _t("Sai sempre dove l'hai messo", 'Always know where you put it');
  String get save => _t('Salva', 'Save');
  String get cancel => _t('Annulla', 'Cancel');
  String get delete => _t('Elimina', 'Delete');
  String get rename => _t('Rinomina', 'Rename');
  String get done => _t('Fatto', 'Done');
  String get undo => _t('Annulla', 'Undo');
  String get create => _t('Crea', 'Create');
  String get edit => _t('Modifica', 'Edit');
  String get color => _t('Colore', 'Colour');
  String get icon => _t('Icona', 'Icon');
  String get name => _t('Nome', 'Name');

  // Ricerca e voce
  String get searchHint => _t('Cosa cerchi?', 'What are you looking for?');
  String get searchByVoice => _t('Cerca a voce', 'Search by voice');
  String get listening => _t('Ti ascolto…', 'Listening…');
  String get sayItemName => _t("Di' il nome di una cosa", 'Say the name of something');
  String get tapToStop => _t('Tocca per fermare', 'Tap to stop');
  String get dictate => _t('Detta', 'Dictate');
  String get voiceUnavailable => _t(
      'La voce non funziona su questo telefono. Controlla il permesso del microfono.',
      "Voice doesn't work on this phone. Check the microphone permission.");
  String get recent => _t('Aggiunti di recente', 'Recently added');
  String get notFoundTitle => _t('Non lo trovo 🤔', "I can't find it 🤔");
  String get notFoundBody => _t("Forse non l'hai ancora aggiunto.", "Maybe you haven't added it yet.");
  String notFoundSpeech(String q) => _t('Non trovo $q.', "I can't find $q.");
  String get readAloud => _t('Leggi ad alta voce', 'Read aloud');
  String foundSpeech(String item, String room, String shelf, int level) => _t(
      '$item: $room, $shelf, piano $level.',
      '$item: $room, $shelf, level $level.');
  String get searchStart => _t(
      'Scrivi o parla. Capisco anche gli errori.',
      'Type or talk. I understand typos too.');
  String get nothingYet => _t(
      'Quando aggiungi delle cose, le trovi qui.',
      "When you add things, you'll find them here.");

  // Stanze
  String get room => _t('Stanza', 'Room');
  String get newRoom => _t('Nuova stanza', 'New room');
  String get roomName => _t('Nome della stanza', 'Room name');
  String get defaultRoomName => _t('Dispensa', 'Pantry');
  String get roomNameHint => _t('Es. Garage, Cantina…', 'E.g. Garage, Cellar…');
  String deleteRoomConfirm(String name) => _t(
      'Eliminare "$name" con tutti i suoi scaffali?',
      'Delete "$name" and all its shelves?');
  String get cantDeleteLastRoom =>
      _t('Serve almeno una stanza.', 'You need at least one room.');

  // Scaffali
  String get newShelf => _t('Nuovo scaffale', 'New shelf');
  String get shelfName => _t('Nome dello scaffale', 'Shelf name');
  String shelfDefaultName(int colorIndex) {
    final c = colorName(colorIndex);
    return _t('Scaffale $c', '$c shelf');
  }

  String colorName(int i) {
    const itNames = ['Blu', 'Rosso', 'Verde', 'Arancione', 'Viola', 'Rosa', 'Azzurro', 'Marrone'];
    const enNames = ['Blue', 'Red', 'Green', 'Orange', 'Purple', 'Pink', 'Sky', 'Brown'];
    return (it ? itNames : enNames)[i % itNames.length];
  }

  String get howManyLevels => _t('Quanti piani?', 'How many levels?');
  String get levelOneIs => _t('Il piano 1 è…', 'Level 1 is…');
  String get atTop => _t('In alto', 'At the top');
  String get atBottom => _t('In basso', 'At the bottom');
  String get flipNumbers => _t('Inverti i numeri dei piani', 'Flip level numbers');
  String get changeColor => _t('Cambia colore', 'Change colour');
  String deleteShelfConfirm(String name) => _t(
      'Eliminare "$name" e tutto quello che c\'è sopra?',
      'Delete "$name" and everything on it?');
  String get emptyRoomTitle => _t("Qui non c'è ancora niente", 'Nothing here yet');
  String get emptyRoomBody => _t(
      'Crea il primo scaffale.\nCi vogliono 10 secondi.',
      'Create your first shelf.\nIt takes 10 seconds.');
  String get dragHint => _t('Tieni premuto per spostare', 'Long-press to move');
  String shelvesCount(int n) =>
      n == 1 ? _t('1 scaffale', '1 shelf') : _t('$n scaffali', '$n shelves');

  // Piani
  String level(int n) => _t('Piano $n', 'Level $n');
  String levelsCount(int n) =>
      n == 1 ? _t('1 piano', '1 level') : _t('$n piani', '$n levels');
  String get addLevel => _t('Aggiungi piano', 'Add level');
  String get deleteLevel => _t('Elimina piano', 'Delete level');
  String deleteLevelConfirm(int n, int count) => count == 0
      ? _t('Eliminare il piano $n?', 'Delete level $n?')
      : _t('Il piano $n ha ${itemsCount(count)}. Eliminarlo?',
          'Level $n has ${itemsCount(count)}. Delete it?');
  String get emptyLevelTitle => _t('Piano vuoto', 'Empty level');
  String get emptyLevelBody =>
      _t('Tocca + per mettere qualcosa.', 'Tap + to put something here.');
  String itemsCount(int n) => n == 0
      ? _t('vuoto', 'empty')
      : (n == 1 ? _t('1 cosa', '1 thing') : _t('$n cose', '$n things'));

  // Foto del piano
  String get levelPhoto => _t('Foto del piano', 'Level photo');
  String get levelPhotoHint => _t(
      'Una foto ti aiuta a ricordare com\'è il piano.',
      'A photo helps you remember what the level looks like.');
  String get takePhoto => _t('Fai una foto', 'Take a photo');
  String get fromGallery => _t('Dalla galleria', 'From gallery');
  String get removePhoto => _t('Togli la foto', 'Remove photo');

  // Oggetti
  String get add => _t('Aggiungi', 'Add');
  String get whatDoYouPut => _t('Cosa metti qui?', 'What are you putting here?');
  String get itemNameHint => _t('Es. Passata, Pasta, Pile…', 'E.g. Tomato sauce, Pasta, Batteries…');
  String get quantity => _t('Quanti?', 'How many?');
  String get note => _t('Nota (facoltativa)', 'Note (optional)');
  String get keepAdding => _t('Aggiungi altro dopo', 'Keep adding');
  String get keepAddingSub => _t(
      'Il foglio resta aperto per la cosa successiva.',
      'The sheet stays open for the next thing.');
  String added(String name) => _t('$name aggiunto ✓', '$name added ✓');
  String get usedUp => _t('Finito', 'Used up');
  String removed(String name) => _t('$name tolto', '$name removed');
  String get moveTo => _t('Sposta', 'Move');
  String get whereDoesItGo => _t('Dove lo metti?', 'Where does it go?');
  String moved(String name) => _t('$name spostato ✓', '$name moved ✓');
  String get editItem => _t('Modifica', 'Edit');
  String get chooseIcon => _t("Scegli un'icona", 'Choose an icon');

  // Impostazioni
  String get settings => _t('Impostazioni', 'Settings');
  String get language => _t('Lingua', 'Language');
  String get languageSystem => _t('Come il telefono', 'Same as phone');
  String get speakResults => _t('Rispondi a voce', 'Answer out loud');
  String get speakResultsSub => _t(
      'Quando cerchi a voce, Trovo ti dice dov\'è.',
      'When you search by voice, Trovo tells you where it is.');
  String get backup => 'Backup';
  String get exportBackup => _t('Salva un backup', 'Save a backup');
  String get exportBackupSub => _t(
      'Crea un file con tutte le stanze e gli scaffali.',
      'Creates a file with all your rooms and shelves.');
  String get importBackup => _t('Ripristina un backup', 'Restore a backup');
  String get importBackupSub =>
      _t('Sostituisce i dati di adesso.', 'Replaces your current data.');
  String get importConfirm => _t(
      'Vuoi sostituire tutto con il backup?',
      'Replace everything with the backup?');
  String get importDone => _t('Backup ripristinato ✓', 'Backup restored ✓');
  String get importError => _t(
      'Questo file non è un backup di Trovo.',
      "This file isn't a Trovo backup.");
  String get restore => _t('Ripristina', 'Restore');
  String get aboutTitle => _t('Informazioni', 'About');
  String get aboutBody => _t(
      'Trovo 1.0 · I tuoi dati restano solo su questo telefono.',
      'Trovo 1.0 · Your data stays on this phone only.');
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<S> load(Locale locale) async => S(locale.languageCode == 'it');

  @override
  bool shouldReload(covariant LocalizationsDelegate<S> old) => false;
}
