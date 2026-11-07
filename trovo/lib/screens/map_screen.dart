import 'package:flutter/material.dart';

import '../store_scope.dart';
import '../widgets/house_map.dart';
import 'shelf_screen.dart';

/// La mappa della casa a schermo intero, con il mobile giusto illuminato.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key, this.highlightShelfId, this.highlightLevelId, this.highlightItemId});
  final String? highlightShelfId;
  final String? highlightLevelId;
  final String? highlightItemId;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.mapView)),
      body: HouseMapView(
        editing: false,
        highlightShelfId: highlightShelfId,
        onOpenShelf: (shelf) => Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ShelfScreen(
            shelfId: shelf.id,
            highlightLevelId: shelf.id == highlightShelfId ? highlightLevelId : null,
            highlightItemId: shelf.id == highlightShelfId ? highlightItemId : null,
          ),
        )),
      ),
    );
  }
}
