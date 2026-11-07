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
  String foundSpeech(String item, String room, String shelf, int level, int position) => _t(
      '$item: $room, $shelf, piano $level, posto $position.',
      '$item: $room, $shelf, level $level, spot $position.');
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

  // Posti
  String slot(int n) => _t('Posto $n', 'Spot $n');
  String get free => _t('Libero', 'Free');
  String get emptySlot => _t('Posto libero: tocca per mettere qualcosa', 'Free spot: tap to put something');
  String get addSlot => _t('Aggiungi un posto', 'Add a spot');
  String get slotsPerLevel => _t('Quanti posti per piano?', 'How many spots per level?');
  String removeSlotConfirm(int n) => _t(
      'Togliere il posto $n? I posti a destra scorrono di uno: ristampa le etichette QR di questo piano.',
      'Remove spot $n? The spots on the right shift by one: reprint the QR labels for this level.');
  String get remove => _t('Togli', 'Remove');
  String get span => _t('Quanti posti occupa?', 'How many spots does it take?');
  String get spanSub => _t('Es. 12 pomarole su 2 file: 6 + 6.', 'E.g. 12 jars in 2 rows: 6 + 6.');
  String get noRoomBeside => _t('Non c\'è spazio accanto. Libera un posto vicino.', 'No room next to it. Free a spot nearby.');
  String get noRoomHere => _t('Qui non c\'è spazio.', 'No room here.');
  String get dragToMove => _t('Tieni premuto e trascina per spostare', 'Long-press and drag to move');

  // Codici a barre e QR
  String get scan => _t('Scansiona', 'Scan');
  String get scanHint => _t('Inquadra un QR di Trovo o un codice a barre', 'Point at a Trovo QR or a barcode');
  String get scanBarcodeHint => _t('Inquadra il codice a barre', 'Point at the barcode');
  String get scanBarcode => _t('Codice a barre', 'Barcode');
  String get unknownCode => _t('Questo codice non è di Trovo.', "This code isn't from Trovo.");
  String get codeNotFound => _t('Questo posto o barattolo non c\'è più.', "This spot or jar doesn't exist anymore.");
  String get productNotHere => _t('Questo prodotto non è ancora negli scaffali.', "This product isn't on your shelves yet.");
  String get addIt => _t('Aggiungilo', 'Add it');
  String get lookingUp => _t('Cerco il prodotto…', 'Looking up the product…');
  String get productNotFound => _t('Prodotto non trovato: scrivi tu il nome.', 'Product not found: type the name.');
  String get cameraUnavailable => _t(
      'La fotocamera non funziona qui. Controlla il permesso della fotocamera.',
      "The camera doesn't work here. Check the camera permission.");

  // Etichette QR
  String get labels => _t('Etichette QR', 'QR labels');
  String get labelsHint => _t(
      'Foglio A4: stampa, ritaglia e attacca con lo scotch.',
      'A4 sheet: print, cut out and stick with tape.');
  String get labelsSlots => _t('Etichette dei posti', 'Spot labels');
  String get labelsSlotsSub => _t('Da attaccare sotto ogni posto, sul bordo del piano.', 'Stick them under each spot, on the edge of the level.');
  String get labelsItems => _t('Etichette per i barattoli', 'Jar labels');
  String get labelsItemsSub => _t(
      'Da attaccare sui barattoli: con una foto Trovo capisce dove sono.',
      'Stick them on your jars: with a photo Trovo knows where they are.');
  String get print => _t('Stampa', 'Print');
  String get saveOrShare => _t('Salva o condividi', 'Save or share');
  String get jar => _t('Barattolo', 'Jar');
  String get nothingToPrint => _t('Non c\'è niente da stampare qui.', 'Nothing to print here.');

  // Foto che aggiorna
  String get photoUpdate => _t('Aggiorna con una foto', 'Update with a photo');
  String get photoUpdateSub => _t(
      'Fotografa un piano: leggo i QR e sposto le cose al posto giusto.',
      'Take a photo of a level: I read the QR codes and move things to the right spot.');
  String get photoReading => _t('Leggo i QR…', 'Reading the QR codes…');
  String get photoNoCodes => _t(
      'Non vedo QR di Trovo. Avvicinati un po\' e controlla la luce.',
      "I can't see any Trovo QR codes. Get a bit closer and check the light.");
  String get photoNoSlots => _t(
      'Vedo i barattoli ma non i QR dei posti. Inquadra anche il bordo del piano.',
      "I can see the jars but not the spot QR codes. Include the edge of the level.");
  String photoAllGood(int n) => _t('Tutto a posto! Ho controllato ${itemsCount(n)}.', 'All good! I checked ${itemsCount(n)}.');
  String get photoChanges => _t('Ho trovato queste modifiche', 'I found these changes');
  String photoApplied(int n) => _t('${itemsCount(n)} aggiornate ✓', '${itemsCount(n)} updated ✓');
  String seen(int n) => _t('ne vedo $n', 'I see $n');
  String get confirm => _t('Conferma', 'Confirm');
  String get photoNotSupported => _t(
      'Qui non posso leggere le foto: usa l\'app sul telefono.',
      "I can't read photos here: use the app on your phone.");

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
