import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../icons.dart';

import '../models.dart';
import '../search.dart';
import '../services/voice.dart';
import '../store_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/sheets.dart';
import '../widgets/shelf_art.dart';
import '../widgets/voice_sheet.dart';
import 'shelf_screen.dart';

/// "Dov'è…?": scrivi o parla, e Trovo ti mostra il mobile, il piano e il posto.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.startWithVoice = false, this.embedded = false});
  final bool startWithVoice;

  /// true: è una scheda della barra in basso (niente tasto indietro).
  final bool embedded;

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (!widget.embedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.startWithVoice ? startVoice() : focusField();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    Voice.instance.stopSpeaking();
    super.dispose();
  }

  void focusField() => _focus.requestFocus();

  Future<void> startVoice() async {
    _focus.unfocus();
    final words = await listenForWords(context);
    if (words == null || !mounted) return;
    final q = cleanVoiceQuery(words);
    setState(() {
      _controller.text = q;
      _query = q;
    });
    final store = context.store;
    if (!store.speakResults) return;
    final results = store.search(q);
    final s = context.s;
    if (results.isEmpty) {
      Voice.instance.speak(s.notFoundSpeech(q), localeTag: s.localeTag);
    } else {
      _speakLocation(results.first.location);
    }
  }

  void _speakLocation(ItemLocation loc) {
    final s = context.s;
    Voice.instance.speak(
      s.foundSpeech(loc.item.name, loc.room.name, loc.shelf.name, loc.levelNumber, loc.positionNumber),
      localeTag: s.localeTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watchStore;
    final s = context.s;
    final theme = Theme.of(context);
    final results = store.search(_query);
    final showRecent = normalize(_query).isEmpty;
    final recent = showRecent ? store.recentItems() : const <ItemLocation>[];
    final bottomPad = widget.embedded ? 120.0 : 32.0;

    Widget body;
    if (showRecent) {
      body = recent.isEmpty
          ? Center(
              child: EmptyState(icon: PIcons.magnifyingGlass, title: s.searchStart, body: s.nothingYet),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                  child: Text(s.recent, style: theme.textTheme.labelMedium?.copyWith(color: TrovoColors.textMuted)),
                ),
                for (var i = 0; i < recent.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ResultTile(
                      location: recent[i],
                      highlight: false,
                      onSpeak: () => _speakLocation(recent[i]),
                    ).animate().fadeIn(delay: Motion.of(context, 30 * math.min(i, 6)), duration: Motion.of(context, 180)),
                  ),
              ],
            );
    } else if (results.isEmpty) {
      body = Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomPad),
          child: EmptyState(
            icon: PIcons.question,
            title: s.notFoundTitle,
            body: s.notFoundBody,
            action: store.allLevels().isEmpty
                ? null
                : SizedBox(
                    width: 260,
                    child: PrimaryButton(
                      icon: PIcons.plusBold,
                      label: '${s.add} "${_query.trim()}"',
                      onPressed: () => showAddItemSheet(context, initialName: _query.trim()),
                    ),
                  ),
          ),
        ),
      );
    } else {
      body = ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad),
        itemCount: results.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ResultTile(
            key: ValueKey(results[i].location.item.id),
            location: results[i].location,
            highlight: true,
            onSpeak: () => _speakLocation(results[i].location),
          )
              .animate()
              .fadeIn(delay: Motion.of(context, 30 * math.min(i, 6)), duration: Motion.of(context, 180))
              .moveY(begin: 8, end: 0, curve: Motion.standard, duration: Motion.of(context, 300)),
        ),
      );
    }

    final page = SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.embedded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Text(s.searchTab, style: theme.textTheme.displaySmall),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(widget.embedded ? 16 : 8, 14, 16, 10),
            child: Row(
              children: [
                if (!widget.embedded) ...[
                  GlassIconButton(
                    icon: PIcons.arrowLeft,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: GlassCard(
                      radius: 26,
                      padding: const EdgeInsets.fromLTRB(16, 0, 7, 0),
                      child: Row(
                        children: [
                          Icon(PIcons.magnifyingGlass, size: 22, color: TrovoColors.text.withValues(alpha: 0.6)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focus,
                              style: theme.textTheme.bodyLarge,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: s.searchHint,
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ),
                          if (_query.isNotEmpty)
                            IconButton(
                              onPressed: () {
                                _controller.clear();
                                setState(() => _query = '');
                                _focus.requestFocus();
                              },
                              icon: const Icon(PIcons.x, size: 20),
                            ),
                          GestureDetector(
                            onTap: startVoice,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: TrovoColors.primary.withValues(alpha: 0.18),
                              ),
                              child: const Icon(PIcons.microphoneFill, size: 20, color: TrovoColors.primaryOnGlass),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );

    if (widget.embedded) return page;
    return AuroraBackground(child: Scaffold(body: page));
  }
}

class _ResultTile extends StatefulWidget {
  const _ResultTile({super.key, required this.location, required this.highlight, required this.onSpeak});
  final ItemLocation location;
  final bool highlight;
  final VoidCallback onSpeak;

  @override
  State<_ResultTile> createState() => _ResultTileState();
}

class _ResultTileState extends State<_ResultTile> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    if (widget.highlight) _pulse.forward();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.location;
    final theme = Theme.of(context);
    final shelf = loc.shelf;
    final tint = TrovoColors.level(loc.level.colorIndex);

    Widget closed(VoidCallback open) => GlassCard(
          radius: 22,
          onTap: open,
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              // Nei "recenti" il piano è acceso fisso; nei risultati pulsa 3 volte.
              final glow = !widget.highlight
                  ? 1.0
                  : (Motion.reduced(context) || _pulse.isCompleted
                      ? 1.0
                      : 0.4 + 0.6 * math.cos(_pulse.value * 3 * math.pi).abs());
              return Row(
                children: [
                  ItemSticker(item: loc.item, size: 54, tint: tint),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.item.name, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        LocationLine(room: loc.room, shelf: shelf, levelIndex: loc.levelIndex, position: loc.positionNumber),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  MiniShelf(
                    width: 44,
                    height: 62,
                    levelColors: [for (final l in shelf.levels) TrovoColors.level(l.colorIndex)],
                    slots: shelfSlots(shelf.levels.map((l) => l.slots)),
                    highlightIndex: loc.levelIndex,
                    highlightPositions: loc.level.positionsOf(loc.item.id).toSet(),
                    glow: glow,
                  ),
                  IconButton(
                    tooltip: context.s.readAloud,
                    onPressed: widget.onSpeak,
                    icon: const Icon(PIcons.speakerHigh, size: 22, color: TrovoColors.textMuted),
                  ),
                ],
              );
            },
          ),
        );

    // Tocca: lo scaffale si apre e parte il "Faro" sul posto giusto.
    return OpenContainer(
      tappable: false,
      transitionDuration: Motion.of(context, 420),
      closedColor: Colors.transparent,
      openColor: TrovoColors.background,
      middleColor: TrovoColors.background,
      closedElevation: 0,
      openElevation: 0,
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      closedBuilder: (context, open) => closed(open),
      openBuilder: (context, _) => ShelfScreen(
        shelfId: shelf.id,
        highlightLevelId: loc.level.id,
        highlightItemId: loc.item.id,
      ),
    );
  }
}
