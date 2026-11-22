import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/scan_controller.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/metro_page.dart';
import '../../core/widgets/pressable.dart';
import '../../data/app_log.dart';
import '../shared/async_view.dart';
import '../shared/excluded_folders.dart';
import '../shared/sheets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final scan = ref.watch(scanProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final controller = ref.read(scanProvider.notifier);

    return Scaffold(
      backgroundColor: Mt.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  const PageHeader('settings'),
                  _BigRow(
                    title: 'home customization',
                    subtitle: 'Choose what appears on your home screen.',
                    onTap: () => _homeCustomization(context, ref),
                  ),
                  const _CategorySection(),
                  _SleepRow(onTap: () => showSleepTimerSheet(context, ref)),
                  _BigRow(
                    title: 'keep playing when closed',
                    subtitle: settings.keepPlaying ? 'on' : 'off',
                    accent: settings.keepPlaying,
                    onTap: () => notifier.setKeepPlaying(!settings.keepPlaying),
                  ),
                  _BigRow(
                    title: 'accent color',
                    subtitle: settings.accent,
                    trailing: Container(
                      width: 26,
                      height: 26,
                      color: settings.accentColor.fill,
                    ),
                    onTap: () => _accentSheet(context, ref),
                  ),
                  _BigRow(
                    title: 'tips',
                    subtitle: 'Support the project',
                    onTap: () => _tips(context),
                  ),

                  // ------------------------------------------------------- sources
                  const SectionLabel('music folders'),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(Mt.pad, 0, Mt.pad, 8),
                    child: Text(
                      'The library scans automatically when the app opens or resumes.',
                      style: Mt.small,
                    ),
                  ),
                  AsyncView<List<SourceInfo>>(
                    value: ref.watch(sourcesProvider),
                    onRetry: () => ref.invalidate(sourcesProvider),
                    builder: (sources) => Column(
                      children: [
                        if (sources.isEmpty)
                          const Padding(
                            padding: EdgeInsets.fromLTRB(Mt.pad, 0, Mt.pad, 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text('no folders yet — add one below',
                                  style: Mt.subtitle),
                            ),
                          ),
                        for (final s in sources)
                          _SourceRow(
                            source: s,
                            onRemove: () async {
                              final ok = await showConfirm(
                                  context, 'stop using this folder?');
                              if (!ok) return;
                              await controller.removeSource(s.path);
                            },
                          ),
                      ],
                    ),
                  ),
                  const SectionLabel('scan exclusions'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: Mt.pad),
                    child: ExcludedFoldersSection(showHeading: false),
                  ),
                  if (scan.scanning) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Mt.pad, 8, Mt.pad, 8),
                      child: LinearProgressIndicator(
                        value: scan.total > 0 ? scan.done / scan.total : null,
                        minHeight: 4,
                        backgroundColor: Mt.outline,
                        color: context.accent,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Mt.pad, 0, Mt.pad, 8),
                      child: Text(
                        scan.total > 0
                            ? 'scanning ${scan.done} of ${scan.total}'
                            : 'scanning…',
                        style: Mt.small,
                      ),
                    ),
                  ] else
                    _ActionRow(
                      icon: AppIcons.refresh,
                      label: 'look for new music',
                      onTap: controller.scan,
                    ),
                  _ActionRow(
                    icon: AppIcons.folder,
                    label: 'add a music folder',
                    onTap: scan.scanning ? null : controller.addFolder,
                  ),
                  if (scan.message != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Mt.pad, 4, Mt.pad, 8),
                      child: Text(scan.message!,
                          style: Mt.small.copyWith(color: context.accent)),
                    ),

                  // ------------------------------------------------------- library
                  const SectionLabel('library'),
                  // ------------------------------------------------------ playback
                  const SectionLabel('playback'),
                  _ActionRow(
                    icon: AppIcons.queue,
                    label: 'open the queue',
                    onTap: () => context.push('/queue'),
                  ),
                  _BigRow(
                    title: 'motion',
                    subtitle: switch (settings.motionMode) {
                      1 => 'reduce motion',
                      2 => 'full motion',
                      _ => 'follow system',
                    },
                    onTap: () => _motionSheet(context, ref),
                  ),

                  // --------------------------------------------------------- about
                  const SectionLabel('about'),
                  _ActionRow(
                    icon: AppIcons.check,
                    label: 'about Metro Player',
                    onTap: () => context.push('/about'),
                  ),
                  _ActionRow(
                    icon: AppIcons.lyrics,
                    label: 'diagnostics',
                    onTap: () => _diagnostics(context, ref),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(Mt.pad, 12, Mt.pad, 0),
                    child: Text(
                      'offline player. your files never leave the device.',
                      style: Mt.small,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _homeCustomization(BuildContext context, WidgetRef ref) {
    return showMetroSheet<void>(
      context,
      builder: (c) => Consumer(
        builder: (c, r, _) {
          final s = r.watch(settingsProvider);
          final n = r.read(settingsProvider.notifier);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SectionLabel('home customization'),
              _SheetSwitch(
                label: 'recently added',
                value: s.showRecent,
                onChanged: n.setShowRecent,
              ),
              _SheetSwitch(
                label: 'favourites',
                value: s.showFavourites,
                onChanged: n.setShowFavourites,
              ),
              _SheetSwitch(
                label: 'most played',
                value: s.showMostPlayed,
                onChanged: n.setShowMostPlayed,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _accentSheet(BuildContext context, WidgetRef ref) async {
    final current = ref.read(settingsProvider).accent;
    await showMetroSheet<void>(
      context,
      builder: (c) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SectionLabel('accent color'),
          for (final a in AccentColor.all)
            Pressable(
              label: '${a.name} accent',
              tilt: false,
              onTap: () {
                ref.read(settingsProvider.notifier).setAccent(a.name);
                Navigator.pop(c);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Mt.pad, vertical: 12),
                child: Row(
                  children: [
                    Container(width: 32, height: 32, color: a.fill),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        a.name,
                        style: Mt.itemTitle.copyWith(
                          fontSize: 24,
                          color: a.name == current ? c.accent : Mt.text,
                        ),
                      ),
                    ),
                    if (a.name == current)
                      MetroIcon(AppIcons.check, size: 20, color: c.accent),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _motionSheet(BuildContext context, WidgetRef ref) {
    final current = ref.read(settingsProvider).motionMode;
    return showMetroSheet<void>(
      context,
      builder: (c) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SectionLabel('motion'),
          for (final e in const {
            0: 'follow system',
            1: 'reduce motion',
            2: 'full motion',
          }.entries)
            SheetItem(
              label: e.value,
              selected: e.key == current,
              onTap: () {
                ref.read(settingsProvider.notifier).setMotionMode(e.key);
                Navigator.pop(c);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _tips(BuildContext context) {
    return showMetroSheet<void>(
      context,
      builder: (c) => const Padding(
        padding: EdgeInsets.fromLTRB(Mt.pad, 8, Mt.pad, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('tips',
                style: TextStyle(
                    fontFamily: Mt.font, fontSize: 26, color: Mt.text)),
            SizedBox(height: 12),
            Text(
              'Long-press a song for play next, queue, playlist and favourites.',
              style: Mt.subtitle,
            ),
            SizedBox(height: 8),
            Text(
              'Swipe the home screen sideways to reach the now playing column.',
              style: Mt.subtitle,
            ),
            SizedBox(height: 8),
            Text(
              'The sleep timer is on this page and on the full player.',
              style: Mt.subtitle,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _diagnostics(BuildContext context, WidgetRef ref) async {
    final db = ref.read(dbProvider);
    final events = await db.events();
    if (!context.mounted) return;
    await showMetroSheet<void>(
      context,
      builder: (c) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Mt.pad, 16, Mt.pad, 4),
              child: Row(
                children: [
                  Expanded(
                      child: Text('diagnostics',
                          style: Mt.itemTitle.copyWith(fontSize: 26))),
                  Pressable(
                    label: 'export diagnostics as text',
                    tilt: false,
                    onTap: () => _exportDiagnostics(context, ref),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('export',
                          style: Mt.rowTitle.copyWith(color: c.accent)),
                    ),
                  ),
                  Pressable(
                    label: 'clear diagnostics',
                    tilt: false,
                    onTap: () async {
                      await db.clearEvents();
                      if (c.mounted) Navigator.pop(c);
                    },
                    child: Text('clear',
                        style: Mt.rowTitle.copyWith(color: c.accent)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: events.isEmpty
                  ? const Center(child: Text('no events', style: Mt.subtitle))
                  : ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, i) {
                        final e = events[i];
                        final time =
                            DateTime.fromMillisecondsSinceEpoch(e.timeMs);
                        return Padding(
                          padding:
                              const EdgeInsets.fromLTRB(Mt.pad, 6, Mt.pad, 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${time.hour.toString().padLeft(2, '0')}:'
                                '${time.minute.toString().padLeft(2, '0')}  ${e.kind}',
                                style: Mt.small,
                              ),
                              Text(e.message,
                                  style: Mt.rowSub.copyWith(color: Mt.text)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportDiagnostics(BuildContext context, WidgetRef ref) async {
    try {
      final events = await ref.read(dbProvider).events();
      final report = StringBuffer()
        ..writeln('Metro Player diagnostic log')
        ..writeln('Generated: ${DateTime.now().toIso8601String()}')
        ..writeln('Events: ${events.length}')
        ..writeln();
      for (final event in events.reversed) {
        final time =
            DateTime.fromMillisecondsSinceEpoch(event.timeMs).toLocal();
        report
          ..writeln('[${time.toIso8601String()}] ${event.kind}')
          ..writeln(event.message)
          ..writeln();
      }

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'export diagnostics',
        fileName: 'metroplayer-diagnostics.txt',
        type: FileType.custom,
        allowedExtensions: const ['txt'],
        bytes: Uint8List.fromList(utf8.encode(report.toString())),
      );
      if (!context.mounted || (path == null && !kIsWeb)) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('diagnostics exported as TXT')),
      );
    } catch (error, stackTrace) {
      AppLog.logError('diagnostics export', error, stackTrace);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('could not export diagnostics: ${error.runtimeType}'),
        ),
      );
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Mt.pad, 12, Mt.pad, 4),
      child: Row(
        children: [
          CircleButton(
            label: 'back',
            icon: AppIcons.back,
            size: 44,
            iconSize: 20,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text('your player', style: Mt.topLabel),
          ),
        ],
      ),
    );
  }
}

class _BigRow extends StatelessWidget {
  const _BigRow({
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.accent = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: title,
      tilt: false,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Mt.pad, 10, Mt.pad, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: Mt.font,
                      fontSize: 30,
                      height: 1.2,
                      color: Mt.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Mt.subtitle.copyWith(
                      color: accent ? context.accent : Mt.dim,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 16),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category =
        ref.watch(settingsProvider.select((s) => s.artistCategory));
    final notifier = ref.read(settingsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(
          'preferred artist category',
          padding: EdgeInsets.fromLTRB(Mt.pad, 20, Mt.pad, 8),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Mt.pad),
          child: Column(
            children: [
              MetroRadio(
                selected: category == 'artist',
                label: 'artists',
                onTap: () => notifier.setArtistCategory('artist'),
              ),
              MetroRadio(
                selected: category == 'album',
                label: 'album artists',
                onTap: () => notifier.setArtistCategory('album'),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(Mt.pad, 12, Mt.pad, 0),
          child: Text(
            'Your choice appears first in the library and is used in artist search.',
            style: Mt.subtitle,
          ),
        ),
      ],
    );
  }
}

class _SleepRow extends ConsumerWidget {
  const _SleepRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.read(audioHandlerProvider).sleepRemaining;
    return ValueListenableBuilder<Duration?>(
      valueListenable: remaining,
      builder: (context, left, _) => _BigRow(
        title: 'sleep timer',
        subtitle: left == null ? 'off' : 'ends in ${fmtDur(left)}',
        onTap: onTap,
      ),
    );
  }
}

class _SheetSwitch extends StatelessWidget {
  const _SheetSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Mt.pad, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Mt.rowTitle)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: context.accent,
          ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source, required this.onRemove});
  final SourceInfo source;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Mt.pad, 4, 8, 4),
      child: Row(
        children: [
          const MetroIcon(AppIcons.folder, size: 20, color: Mt.dim),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.path,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Mt.rowSub.copyWith(color: Mt.text),
                ),
                Text('${source.tracks} tracks', style: Mt.small),
              ],
            ),
          ),
          Pressable(
            label: 'remove folder',
            tilt: false,
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: MetroIcon(AppIcons.close, size: 18, color: Mt.dim),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.label, this.onTap});
  final String icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: label,
      tilt: false,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Mt.pad, vertical: 14),
        child: Row(
          children: [
            MetroIcon(icon, size: 22, color: context.accent),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: Mt.rowTitle)),
            const MetroIcon(AppIcons.chevronDown, size: 18, color: Mt.faint),
          ],
        ),
      ),
    );
  }
}
