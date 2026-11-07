import 'models.dart';

/// Mobili già pronti, con le forme e le misure più comuni.
/// (Niente nomi di marchi: solo forme generiche.)
enum TemplateId { shelf, drawers, wardrobe, cubes, kitchenBase, kitchenWall, bathroom, nightstand }

/// Un numero da scegliere quando crei il mobile (es. "Quanti cassetti?").
enum ParamKey { levels, slots, drawers, hangers, rows, cols, boards }

class TemplateParam {
  const TemplateParam(this.key, this.initial, this.min, this.max);
  final ParamKey key;
  final int initial;
  final int min;
  final int max;
}

class FurnitureTemplate {
  const FurnitureTemplate({
    required this.id,
    required this.kind,
    required this.feminine,
    required this.params,
  });

  final TemplateId id;
  final FurnitureKind kind;

  /// Per l'italiano: "Cassettiera Rossa" ma "Armadio Rosso".
  final bool feminine;
  final List<TemplateParam> params;

  Map<ParamKey, int> get defaults => {for (final p in params) p.key: p.initial};
}

const furnitureTemplates = <FurnitureTemplate>[
  FurnitureTemplate(
    id: TemplateId.shelf,
    kind: FurnitureKind.shelf,
    feminine: false,
    params: [TemplateParam(ParamKey.levels, 5, 1, 20), TemplateParam(ParamKey.slots, 5, 1, 30)],
  ),
  FurnitureTemplate(
    id: TemplateId.drawers,
    kind: FurnitureKind.drawers,
    feminine: true,
    params: [TemplateParam(ParamKey.drawers, 4, 1, 10)],
  ),
  FurnitureTemplate(
    id: TemplateId.wardrobe,
    kind: FurnitureKind.wardrobe,
    feminine: false,
    params: [TemplateParam(ParamKey.hangers, 8, 2, 30), TemplateParam(ParamKey.drawers, 2, 0, 6)],
  ),
  FurnitureTemplate(
    id: TemplateId.cubes,
    kind: FurnitureKind.cubes,
    feminine: true,
    params: [TemplateParam(ParamKey.rows, 3, 1, 6), TemplateParam(ParamKey.cols, 3, 1, 6)],
  ),
  FurnitureTemplate(
    id: TemplateId.kitchenBase,
    kind: FurnitureKind.drawers,
    feminine: true,
    params: [TemplateParam(ParamKey.drawers, 3, 1, 5)],
  ),
  FurnitureTemplate(
    id: TemplateId.kitchenWall,
    kind: FurnitureKind.cabinet,
    feminine: false,
    params: [TemplateParam(ParamKey.boards, 2, 1, 5)],
  ),
  FurnitureTemplate(
    id: TemplateId.bathroom,
    kind: FurnitureKind.cabinet,
    feminine: false,
    params: [TemplateParam(ParamKey.drawers, 2, 0, 4), TemplateParam(ParamKey.boards, 1, 0, 3)],
  ),
  FurnitureTemplate(
    id: TemplateId.nightstand,
    kind: FurnitureKind.cabinet,
    feminine: false,
    params: [TemplateParam(ParamKey.drawers, 1, 0, 3), TemplateParam(ParamKey.boards, 1, 0, 2)],
  ),
];

FurnitureTemplate templateById(TemplateId id) => furnitureTemplates.firstWhere((t) => t.id == id);

/// Crea gli scomparti del mobile (dall'alto verso il basso).
/// Il colore di ogni scomparto segue il suo numero.
List<Level> buildLevels(TemplateId id, Map<ParamKey, int> p, {bool numberFromTop = true}) {
  int v(ParamKey k) => p[k] ?? templateById(id).defaults[k] ?? 1;
  final out = <Level>[];

  void add(LevelKind kind, int slots, {int columns = 3}) {
    out.add(Level(colorIndex: 0, kind: kind, slotCount: slots, columns: columns));
  }

  switch (id) {
    case TemplateId.shelf:
      for (var i = 0; i < v(ParamKey.levels); i++) {
        add(LevelKind.board, v(ParamKey.slots));
      }
    case TemplateId.drawers:
    case TemplateId.kitchenBase:
      for (var i = 0; i < v(ParamKey.drawers); i++) {
        add(LevelKind.drawer, 6);
      }
    case TemplateId.wardrobe:
      add(LevelKind.board, 4);
      add(LevelKind.rail, v(ParamKey.hangers));
      for (var i = 0; i < v(ParamKey.drawers); i++) {
        add(LevelKind.drawer, 6);
      }
    case TemplateId.cubes:
      for (var i = 0; i < v(ParamKey.rows) * v(ParamKey.cols); i++) {
        add(LevelKind.cube, 2, columns: 2);
      }
    case TemplateId.kitchenWall:
      for (var i = 0; i < v(ParamKey.boards); i++) {
        add(LevelKind.board, 4);
      }
    case TemplateId.bathroom:
    case TemplateId.nightstand:
      for (var i = 0; i < v(ParamKey.drawers); i++) {
        add(LevelKind.drawer, 6);
      }
      for (var i = 0; i < v(ParamKey.boards); i++) {
        add(LevelKind.board, 3);
      }
  }
  if (out.isEmpty) add(LevelKind.board, 3);

  // Colori: ogni scomparto prende il colore del suo numero.
  final shelf = Shelf(name: '', colorIndex: 0, numberFromTop: numberFromTop, levels: out);
  for (var i = 0; i < out.length; i++) {
    out[i].colorIndex = shelf.levelNumber(i) - 1 + (out[i].kind == LevelKind.drawer ? 2 : 0);
  }
  return out;
}
