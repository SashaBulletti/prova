import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../icons.dart';
import 'package:share_plus/share_plus.dart';

import '../store_scope.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/labels_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _export(BuildContext context) async {
    final json = context.store.exportJson();
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final name = 'trovo-backup-$date.json';
    try {
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(utf8.encode(json), mimeType: 'application/json', name: name)],
        fileNameOverrides: [name],
        subject: 'Trovo backup $date',
      ));
    } catch (e) {
      debugPrint('Trovo: backup non riuscito ($e)');
    }
  }

  Future<void> _import(BuildContext context) async {
    final s = context.s;
    final store = context.store;
    try {
      final file = await FilePicker.pickFile(type: FileType.any);
      if (file == null || !context.mounted) return;
      final raw = utf8.decode(await file.readAsBytes(), allowMalformed: true);
      if (!context.mounted) return;
      final ok = await confirmDialog(context, s.importConfirm, confirmLabel: s.restore, danger: false);
      if (!ok || !context.mounted) return;
      final done = store.importJson(raw);
      showToast(context, done ? s.importDone : s.importError);
    } catch (e) {
      if (context.mounted) showToast(context, s.importError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watchStore;
    final s = context.s;
    final theme = Theme.of(context);

    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 10),
          child: Text(title, style: theme.textTheme.labelMedium?.copyWith(color: TrovoColors.textMuted)),
        );

    Widget group(List<Widget> children) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassCard(
            radius: 22,
            shadow: false,
            child: Column(children: children),
          ),
        );

    Widget langTile(String? code, String label) => RadioListTile<String?>(value: code, title: Text(label));

    return AuroraBackground(
      child: Scaffold(
        appBar: AppBar(
          leadingWidth: 64,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(
              child: GlassIconButton(
                icon: PIcons.arrowLeft,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          title: Text(s.settings),
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            section(s.language),
            group([
              RadioGroup<String?>(
                groupValue: store.localeCode,
                onChanged: store.setLocale,
                child: Column(
                  children: [
                    langTile(null, s.languageSystem),
                    langTile('it', 'Italiano'),
                    langTile('en', 'English'),
                  ],
                ),
              ),
            ]),
            section(s.searchByVoice),
            group([
              SwitchListTile(
                value: store.speakResults,
                onChanged: store.setSpeakResults,
                secondary: const Icon(PIcons.speakerHigh),
                title: Text(s.speakResults),
                subtitle: Text(s.speakResultsSub),
              ),
            ]),
            section(s.appearance),
            group([
              SwitchListTile(
                value: store.solidGlass,
                onChanged: store.setSolidGlass,
                secondary: const Icon(PIcons.squaresFour),
                title: Text(s.solidGlass),
                subtitle: Text(s.solidGlassSub),
              ),
            ]),
            section(s.backup),
            group([
              ListTile(
                leading: const Icon(PIcons.downloadSimple, size: 26),
                title: Text(s.exportBackup),
                subtitle: Text(s.exportBackupSub),
                onTap: () => _export(context),
              ),
              Divider(height: 1, indent: 16, endIndent: 16, color: Colors.white.withValues(alpha: 0.08)),
              ListTile(
                leading: const Icon(PIcons.arrowCounterClockwise, size: 26),
                title: Text(s.importBackup),
                subtitle: Text(s.importBackupSub),
                onTap: () => _import(context),
              ),
            ]),
            section(s.labels),
            group([
              ListTile(
                leading: const Icon(PIcons.qrCode, size: 26),
                title: Text(s.labels),
                subtitle: Text(s.labelsHint),
                onTap: () => showLabelsSheet(context),
              ),
            ]),
            section(s.aboutTitle),
            group([
              ListTile(
                leading: const Icon(PIcons.info, size: 26),
                title: Text(s.tagline),
                subtitle: Text(s.aboutBody),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
