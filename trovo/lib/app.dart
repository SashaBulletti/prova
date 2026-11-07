import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/strings.dart';
import 'screens/home_screen.dart';
import 'store.dart';
import 'store_scope.dart';
import 'theme.dart';

class TrovoApp extends StatefulWidget {
  const TrovoApp({super.key, required this.store});
  final PantryStore store;

  @override
  State<TrovoApp> createState() => _TrovoAppState();
}

class _TrovoAppState extends State<TrovoApp> {
  late String? _locale = widget.store.localeCode;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
    // Salva subito quando l'app va in background.
    _lifecycle = AppLifecycleListener(
      onHide: widget.store.saveNow,
      onPause: widget.store.saveNow,
    );
  }

  void _onStore() {
    if (widget.store.localeCode != _locale) {
      setState(() => _locale = widget.store.localeCode);
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: widget.store,
      child: MaterialApp(
        title: 'Trovo',
        debugShowCheckedModeBanner: false,
        theme: TrovoTheme.dark(),
        darkTheme: TrovoTheme.dark(),
        themeMode: ThemeMode.dark,
        locale: _locale == null ? null : Locale(_locale!),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (device, supported) {
          if (device?.languageCode == 'it') return const Locale('it');
          return const Locale('en');
        },
        home: const HomeScreen(),
      ),
    );
  }
}
