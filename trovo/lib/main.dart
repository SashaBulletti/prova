import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'l10n/strings.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: TrovoColors.background,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  final isItalian = PlatformDispatcher.instance.locale.languageCode == 'it';
  final store = await PantryStore.load(defaultRoomName: S(isItalian).defaultRoomName);

  runApp(TrovoApp(store: store));
}
