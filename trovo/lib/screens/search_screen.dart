import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models.dart';
import '../search.dart';
import '../services/voice.dart';
import '../store_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';
import '../widgets/shelf_art.dart';
import '../widgets/voice_sheet.dart';
import 'shelf_screen.dart';

/// "Dov'è…?": scrivi o parla, e Trovo ti mostra lo scaffale e il piano.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.startWithVoice = false});
  final bool startWithVoice;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.startWithVoice) {
        _voice();
      } else {
        _focus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    Voice.instance.stopSpeaking();
    super.dispose();
  }

  Future<void> _voice() async {
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
      s.foundSpeech(loc.item.name, loc.room.name, loc.shelf.name, loc.levelNumber),
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

    Widget body;
    if (showRecent) {
      body = recent.isEmpty
          ? Center(
              child: EmptyState(
                art: const Text('🔎', style: TextStyle(fontSize: 64)),
                title: s.searchStart,
                body: s.nothingYet,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                  child: Text(s.recent, style: theme.textTheme.titleSmall?.copyWith(color: TrovoColors.textMuted)),
                ),
                for (var i = 0; i < recent.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ResultTile(
                      location: recent[i],
                      highlight: false,
                      onSpeak: () => _speakLocation(recent[i]),
                    ).animate().fadeIn(delay: Motion.of(context, 40 * i), duration: Motion.of(context, 220)),
                  ),
              ],
            );
    } else if (results.isEmpty) {
      body = Center(
        child: SingleChildScrollView(
          child: EmptyState(
            art: const Text('🤷', style: TextStyle(fontSize: 64))
                .animate()
                .shake(hz: 3, duration: Motion.of(context, 500)),
            title: s.notFoundTitle,
            body: s.notFoundBody,
            action: store.allLevels().isEmpty
                ? null
                : FilledButton.icon(
                    onPressed: () => showAddItemSheet(context, initialName: _query.trim()),
                    icon: const Icon(Icons.add_rounded),
                    label: Text('${s.add} "${_query.trim()}"'),
                  ),
          ),
        ),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
              .fadeIn(delay: Motion.of(context, 40 * math.min(i, 8)), duration: Motion.of(context, 200))
              .slideY(begin: 0.1, curve: Curves.easeOutCubic, duration: Motion.of(context, 260)),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    iconSize: 28,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Hero(
                      tag: 'search-bar',
                      child: Material(
                        color: TrovoColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(22),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, size: 28, color: TrovoColors.textMuted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focus,
                                  style: theme.textTheme.titleMedium,
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    hintText: s.searchHint,
                                    filled: false,
                                    border: InputBorder.none,
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
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              MicButton(onPressed: _voice, size: 48),
                            ],
                          ),
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
      ),
    );
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

    Widget closed(VoidCallback open) => Material(
          color: TrovoColors.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.selectionClick();
              open();
            },
            child: Padding(
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
                      ItemSticker(item: loc.item, size: 56),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.item.name, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            LocationLine(room: loc.room, shelf: shelf, levelIndex: loc.levelIndex),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      MiniShelf(
                        width: 46,
                        height: 64,
                        levelColors: [for (final l in shelf.levels) TrovoColors.level(l.colorIndex)],
                        itemCounts: [for (final l in shelf.levels) l.items.length],
                        highlightIndex: loc.levelIndex,
                        glow: glow,
                      ),
                      IconButton(
                        tooltip: context.s.readAloud,
                        onPressed: widget.onSpeak,
                        icon: const Icon(Icons.volume_up_rounded, size: 26),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

    // Tocca: lo scaffale si apre e parte il "Faro" sul piano giusto.
    return OpenContainer(
      tappable: false,
      transitionDuration: Motion.of(context, 450),
      closedColor: TrovoColors.surface,
      openColor: TrovoColors.background,
      middleColor: TrovoColors.background,
      closedElevation: 0,
      openElevation: 0,
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      closedBuilder: (context, open) => closed(open),
      openBuilder: (context, _) => ShelfScreen(
        shelfId: shelf.id,
        highlightLevelId: loc.level.id,
        highlightItemId: loc.item.id,
      ),
    );
  }
}
