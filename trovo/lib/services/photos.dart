// Foto dei piani: sul telefono vengono copiate nella cartella dell'app,
// così non spariscono quando il sistema pulisce la cache.
export 'photos_web.dart' if (dart.library.io) 'photos_io.dart';
