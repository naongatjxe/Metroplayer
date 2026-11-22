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
import '../shared/async_view.dart';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MetroPage(
      label: 'my library',
      header: 'playlists',
      actions: [
        CircleButton(
          label: 'new playlist',
          icon: AppIcons.add,
          size: 44,
          iconSize: 20,
          onTap: () async {
            final id = await createPlaylistFlow(context, ref);
            if (id != null && context.mounted) context.push('/playlists/$id');
          },
        ),
      ],
      child: AsyncView<List<PlaylistSummary>>(
        value: ref.watch(playlistsProvider),
        onRetry: () => ref.invalidate(playlistsProvider),
        builder: (playlists) => playlists.isEmpty
            ? EmptyState(
                message: 'no playlists yet',
                actionLabel: '+ new playlist',
                onAction: () => createPlaylistFlow(context, ref),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemExtent: 72,
                itemCount: playlists.length,
                itemBuilder: (context, i) {
                  final p = playlists[i];
                  return Pressable(
                    label: '${p.name}, ${p.count} tracks',
                    tilt: false,
                    onTap: () => context.push('/playlists/${p.id}'),
                    onLongPress: () => _options(context, ref, p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            color: Mt.surfaceAlt,
                            child: const Center(
                              child: MetroIcon(AppIcons.addToPlaylist,
                                  size: 24, color: Mt.dim),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Mt.rowTitle),
                                Text(
                                  '${p.count} tracks  ·  ${fmtTotal(p.durationMs)}',
                                  style: Mt.rowSub,
                                ),
                              ],
                            ),
                          ),
                          Pressable(
                            label: 'playlist options',
                            tilt: false,
                            onTap: () => _options(context, ref, p),
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: MetroIcon(AppIcons.more,
                                  size: 20, color: Mt.dim),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _options(
      BuildContext context, WidgetRef ref, PlaylistSummary p) async {
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
      final name = await showTextDialog(context,
          title: 'rename playlist', initial: p.name, ok: 'save');
      if (name == null || name.trim().isEmpty) return;
      await db.renamePlaylist(p.id, name.trim());
      bumpLibraryWidget(ref);
    } else if (action == 'delete') {
      final ok = await showConfirm(context, 'delete "${p.name}"?');
      if (!ok) return;
      await db.deletePlaylist(p.id);
      bumpLibraryWidget(ref);
    }
  }
}
