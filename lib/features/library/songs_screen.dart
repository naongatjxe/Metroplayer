import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/widgets/alpha_grouped_list.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/metro_page.dart';
import '../../core/widgets/pressable.dart';
import '../../domain/models.dart';
import '../shared/async_view.dart';
import '../shared/track_tile.dart';

class SongsScreen extends ConsumerWidget {
  const SongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MetroPage(
      label: 'my library',
      header: 'songs',
      actions: [
        CircleButton(
          label: 'search',
          icon: AppIcons.search,
          size: 44,
          iconSize: 20,
          onTap: () => context.push('/search'),
        ),
      ],
      child: AsyncView<List<Track>>(
        value: ref.watch(songsProvider),
        onRetry: () => ref.invalidate(songsProvider),
        builder: (songs) => songs.isEmpty
            ? const EmptyState(message: 'no songs yet')
            : _SongsList(songs),
      ),
    );
  }
}

class _SongsList extends StatelessWidget {
  const _SongsList(this.songs);
  final List<Track> songs;

  @override
  Widget build(BuildContext context) {
    return AlphaGroupedListView<Track>(
      items: songs,
      labelOf: (track) => track.title,
      itemName: 'song',
      itemCountLabel: 'songs',
      itemExtent: trackTileHeight,
      itemBuilder: (context, track, index, orderedSongs) => TrackTile(
        track,
        key: ValueKey(track.id),
        queue: orderedSongs,
        index: index,
      ),
    );
  }
}
