import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/actions.dart';
import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/metro_page.dart';
import '../../core/widgets/pressable.dart';
import '../../domain/models.dart';
import '../shared/artwork.dart';
import '../shared/async_view.dart';

class PlaylistScreen extends ConsumerWidget {
  const PlaylistScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists =
        ref.watch(playlistsProvider).valueOrNull ?? const <PlaylistSummary>[];
    PlaylistSummary? summary;
    for (final p in playlists) {
      if (p.id == id) summary = p;
    }
    final name = summary?.name ?? 'playlist';

    return MetroPage(
      label: name,
      actions: [
        CircleButton(
          label: 'playlist options',
          icon: AppIcons.more,
          size: 44,
          iconSize: 20,
          onTap: () => _options(context, ref, summary, name),
        ),
      ],
      child: AsyncView<List<PlaylistEntry>>(
        value: ref.watch(playlistEntriesProvider(id)),
        onRetry: () => ref.invalidate(playlistEntriesProvider(id)),
        builder: (entries) =>
            _PlaylistView(id: id, name: name, entries: entries),
      ),
    );
  }

  Future<void> _options(
    BuildContext context,
    WidgetRef ref,
    PlaylistSummary? summary,
    String name,
  ) async {
    final action = await showMetroSheet<String>(
      context,
      builder: (c) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetItem(label: 'rename', onTap: () => Navigator.pop(c, 'rename')),
          SheetItem(label: 'delete', onTap: () => Navigator.pop(c, 'delete')),
        ],
      ),
    );
    if (action == null || !context.mounted) return;
    final db = ref.read(dbProvider);
    if (action == 'rename') {
      final next = await showTextDialog(context,
          title: 'rename playlist', initial: name, ok: 'save');
      if (next == null || next.trim().isEmpty) return;
      await db.renamePlaylist(id, next.trim());
      bumpLibraryWidget(ref);
    } else if (action == 'delete') {
      final ok = await showConfirm(context, 'delete "$name"?');
      if (!ok) return;
      await db.deletePlaylist(id);
      bumpLibraryWidget(ref);
      if (context.mounted) context.pop();
    }
  }
}

class _PlaylistView extends ConsumerStatefulWidget {
  const _PlaylistView(
      {required this.id, required this.name, required this.entries});
  final int id;
  final String name;
  final List<PlaylistEntry> entries;

  @override
  ConsumerState<_PlaylistView> createState() => _PlaylistViewState();
}

class _PlaylistViewState extends ConsumerState<_PlaylistView> {
  late List<PlaylistEntry> _entries = List.of(widget.entries);

  @override
  void didUpdateWidget(covariant _PlaylistView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries) {
      _entries = List.of(widget.entries);
    }
  }

  Future<void> _remove(int entryId) async {
    await ref.read(dbProvider).removeFromPlaylist(entryId);
    bumpLibraryWidget(ref);
    if (mounted) {
      setState(() => _entries.removeWhere((e) => e.entryId == entryId));
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    setState(() {
      final item = _entries.removeAt(oldIndex);
      _entries.insert(newIndex, item);
    });
    await ref
        .read(dbProvider)
        .reorderPlaylist(widget.id, [for (final e in _entries) e.entryId]);
    bumpLibraryWidget(ref);
  }

  @override
  Widget build(BuildContext context) {
    final tracks = [for (final e in _entries) e.track];
    final totalMs = tracks.fold<int>(0, (a, t) => a + t.durationMs);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Mt.pad, 0, Mt.pad, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Mt.itemTitle),
                    Text('${tracks.length} tracks  ·  ${fmtTotal(totalMs)}',
                        style: Mt.small),
                  ],
                ),
              ),
              CircleButton(
                label: 'play playlist',
                icon: AppIcons.play,
                onTap: tracks.isEmpty ? null : () => playTracks(ref, tracks, 0),
              ),
              const SizedBox(width: 10),
              CircleButton(
                label: 'shuffle playlist',
                icon: AppIcons.shuffle,
                onTap: tracks.isEmpty ? null : () => playShuffled(ref, tracks),
              ),
            ],
          ),
        ),
        Expanded(
          child: _entries.isEmpty
              ? const EmptyState(message: 'this playlist is empty')
              : ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  buildDefaultDragHandles: false,
                  itemCount: _entries.length,
                  onReorderItem: _reorder,
                  itemBuilder: (context, i) {
                    final entry = _entries[i];
                    return SizedBox(
                      key: ValueKey(entry.entryId),
                      height: 72,
                      child: Pressable(
                        label: '${entry.track.title}, ${entry.track.artist}',
                        tilt: false,
                        onTap: () => playTracks(ref, tracks, i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Artwork(artKey: entry.track.artKey, size: 56),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      entry.track.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Mt.rowTitle,
                                    ),
                                    Text(
                                      '${entry.track.artist}  ·  ${fmtDur(entry.track.duration)}',
                                      style: Mt.rowSub,
                                    ),
                                  ],
                                ),
                              ),
                              Pressable(
                                label: 'remove from playlist',
                                tilt: false,
                                onTap: () => _remove(entry.entryId),
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: MetroIcon(AppIcons.close,
                                      size: 18, color: Mt.dim),
                                ),
                              ),
                              ReorderableDragStartListener(
                                index: i,
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: MetroIcon(AppIcons.dragHandle,
                                      size: 20, color: Mt.dim),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
