import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../furniture_templates.dart';
import '../models.dart';
import '../store_scope.dart';
import '../theme.dart';
import 'common.dart';
import 'furniture_art.dart';
import 'sheets.dart' show ShelfColorPicker;

/// "Nuovo mobile": scegli il tipo (scaffale, cassettiera, armadio, cubi…),
/// regola i numeri e lo vedi disegnato mentre scegli.
Future<Shelf?> showNewFurnitureSheet(BuildContext context, Room room) => showModalBottomSheet<Shelf>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _NewFurnitureSheet(room: room),
      ),
    );

class _NewFurnitureSheet extends StatefulWidget {
  const _NewFurnitureSheet({required this.room});
  final Room room;

  @override
  State<_NewFurnitureSheet> createState() => _NewFurnitureSheetState();
}

class _NewFurnitureSheetState extends State<_NewFurnitureSheet> {
  FurnitureTemplate _template = furnitureTemplates.first;
  late Map<ParamKey, int> _params = _template.defaults;
  late int _color = context.store.nextShelfColor(widget.room);
  bool _fromTop = true;
  late final TextEditingController _name = TextEditingController(text: _defaultName());
  bool _nameEdited = false;

  String _defaultName() => context.s.furnitureDefaultName(_template.id, _color, _template.feminine);

  void _refreshName() {
    if (!_nameEdited) _name.text = _defaultName();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _create() {
    final name = _name.text.trim().isEmpty ? _defaultName() : _name.text;
    HapticFeedback.mediumImpact();
    final shelf = context.store.addFurniture(
      widget.room,
      template: _template.id,
      params: _params,
      name: name,
      colorIndex: _color,
      numberFromTop: _fromTop,
    );
    Navigator.pop(context, shelf);
  }

  List<MiniCompartment> _preview(FurnitureTemplate t, Map<ParamKey, int> p) {
    final levels = buildLevels(t.id, p, numberFromTop: _fromTop);
    return [
      for (var i = 0; i < levels.length; i++)
        MiniCompartment(
          levels[i].kind,
          TrovoColors.level(levels[i].colorIndex),
          // Qualche posto "pieno" per far capire com'è.
          [for (var s = 0; s < levels[i].slotCount; s++) (s + i) % 3 != 2],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final cubes = _template.id == TemplateId.cubes;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
            child: Text(s.newFurniture, style: theme.textTheme.headlineSmall),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Text(s.whatFurniture, style: theme.textTheme.bodySmall),
          ),
          // Tipi di mobile, con il disegno.
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: furnitureTemplates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final t = furnitureTemplates[i];
                final selected = t.id == _template.id;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _template = t;
                      _params = t.defaults;
                      _refreshName();
                    });
                  },
                  child: AnimatedContainer(
                    duration: Motion.of(context, 200),
                    width: 108,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    decoration: BoxDecoration(
                      color: selected ? TrovoColors.primary.withValues(alpha: 0.16) : TrovoColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: selected ? TrovoColors.primary : Colors.transparent, width: 2),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, c) => MiniFurniture(
                              kind: t.kind,
                              compartments: _preview(t, t.defaults),
                              gridColumns: t.id == TemplateId.cubes ? t.defaults[ParamKey.cols]! : 1,
                              bodyColor: TrovoColors.shelf(_color),
                              width: c.maxWidth * 0.8,
                              height: c.maxHeight,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.templateName(t.id),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: selected ? TrovoColors.text : TrovoColors.textMuted,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Anteprima grande.
                    AnimatedSwitcher(
                      duration: Motion.of(context, 220),
                      child: MiniFurniture(
                        key: ValueKey('${_template.id}-${_params.values.join('-')}-$_fromTop-$_color'),
                        kind: _template.kind,
                        compartments: _preview(_template, _params),
                        gridColumns: cubes ? (_params[ParamKey.cols] ?? 3) : 1,
                        bodyColor: TrovoColors.shelf(_color),
                        width: 120,
                        height: 180,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final p in _template.params) ...[
                            _Label(s.paramLabel(p.key)),
                            QuantityStepper(
                              value: _params[p.key] ?? p.initial,
                              min: p.min,
                              max: p.max,
                              big: true,
                              onChanged: (v) => setState(() => _params = {..._params, p.key: v}),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_template.id == TemplateId.shelf) ...[
                            _Label(s.levelOneIs),
                            SegmentedButton<bool>(
                              showSelectedIcon: false,
                              segments: [
                                ButtonSegment(value: true, label: Text(s.atTop)),
                                ButtonSegment(value: false, label: Text(s.atBottom)),
                              ],
                              selected: {_fromTop},
                              onSelectionChanged: (v) => setState(() => _fromTop = v.first),
                              style: SegmentedButton.styleFrom(
                                selectedBackgroundColor: TrovoColors.primary,
                                selectedForegroundColor: TrovoColors.onPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _Label(s.color),
                ShelfColorPicker(
                  value: _color,
                  onChanged: (i) => setState(() {
                    _color = i;
                    _refreshName();
                  }),
                ),
                const SizedBox(height: 18),
                _Label(s.name),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  style: theme.textTheme.bodyLarge,
                  onChanged: (_) => _nameEdited = true,
                  onSubmitted: (_) => _create(),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: _create,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(s.create),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: TrovoColors.textMuted)),
      );
}
