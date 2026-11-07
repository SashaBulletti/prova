import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../icons.dart';

import '../store_scope.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import 'home_screen.dart';
import 'scan_screen.dart';
import 'search_screen.dart';

/// Struttura principale: schede in alto e barra di vetro flottante in basso.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tab = 0;
  final _searchKey = GlobalKey<SearchScreenState>();

  void _goSearch({bool voice = false}) {
    HapticFeedback.selectionClick();
    setState(() => _tab = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final st = _searchKey.currentState;
      if (st == null) return;
      voice ? st.startVoice() : st.focusField();
    });
  }

  void _scan() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return AuroraBackground(
      child: Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: IndexedStack(
          index: _tab,
          children: [
            HomeScreen(onSearch: () => _goSearch(), onVoice: () => _goSearch(voice: true)),
            SearchScreen(key: _searchKey, embedded: true),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
          child: Row(
            children: [
              Expanded(
                child: _TabBar(
                  index: _tab,
                  items: [
                    _TabItem(PIcons.house, PIcons.houseFill, s.homeTab),
                    _TabItem(PIcons.magnifyingGlass, PIcons.magnifyingGlassFill, s.searchTab),
                  ],
                  onChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _tab = i);
                  },
                ),
              ),
              const SizedBox(width: 12),
              _ScanButton(onTap: _scan, label: s.scan),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.items, required this.onChanged});
  final int index;
  final List<_TabItem> items;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: GlassBar(
        radius: 32,
        padding: const EdgeInsets.all(6),
        child: LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth / items.length;
          return Stack(
            children: [
              // Pillola che scorre sotto la scheda scelta.
              AnimatedPositioned(
                duration: Motion.of(context, 320),
                curve: Motion.snappy,
                left: index * w,
                width: w,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: Semantics(
                        selected: i == index,
                        button: true,
                        label: items[i].label,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(i),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                i == index ? items[i].selectedIcon : items[i].icon,
                                size: 24,
                                color: i == index ? TrovoColors.primaryOnGlass : TrovoColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                items[i].label,
                                style: TextStyle(
                                  fontFamily: TrovoTheme.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: i == index ? TrovoColors.text : TrovoColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Scansiona: l'azione principale, sempre a un tocco.
class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onTap, required this.label});
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: PressScale(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [TrovoColors.primary, TrovoColors.primaryEnd],
              ),
              boxShadow: [
                BoxShadow(color: TrovoColors.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10)),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Colors.white.withValues(alpha: 0.28), Colors.white.withValues(alpha: 0)],
              ),
            ),
            child: const Icon(PIcons.scanBold, color: TrovoColors.onPrimary, size: 28),
          ),
        ),
      ),
    );
  }
}
