import 'package:flutter/widgets.dart';

import 'l10n/strings.dart';
import 'store.dart';

/// Rende lo store disponibile a tutte le schermate.
class StoreScope extends InheritedNotifier<PantryStore> {
  const StoreScope({super.key, required PantryStore store, required super.child})
      : super(notifier: store);

  /// Legge lo store e ricostruisce il widget quando cambia.
  static PantryStore watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  /// Legge lo store senza ricostruire (per le azioni).
  static PantryStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

extension StoreContext on BuildContext {
  PantryStore get store => StoreScope.read(this);
  PantryStore get watchStore => StoreScope.watch(this);
  S get s => S.of(this);
}
