import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/actions.dart';
import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/metro_page.dart';
import '../../core/widgets/pressable.dart';
import '../../domain/models.dart';
import '../shared/async_view.dart';
import '../shared/track_tile.dart';

const _titles = {
  'favourites': 'favourites',
  'most_played': 'most played',
  'recent_played': 'recently played',
  'never_played': 'never played',
};

const _subtitles = {
  'favourites': 'tracks you loved',
  'most_played': 'on repeat',
  'recent_played': 'back in rotation',
  'never_played': 'still to discover',
};

class AutoListScreen extends ConsumerWidget {
  const AutoListScreen({super.key, required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = _titles[kind] ?? 'tracks';
    return MetroPage(
      label: 'my library',
      header: title,
      child: AsyncView<List<Track>>(
        value: ref.watch(autoPlaylistProvider(kind)),
        onRetry: () => ref.invalidate(autoPlaylistProvider(kind)),
        builder: (tracks) {
          if (tracks.isEmpty) {
            return EmptyState(message: 'nothing in $title yet');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Mt.pad, 0, Mt.pad, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${tracks.length} tracks  ·  ${_subtitles[kind] ?? ''}',
                        style: Mt.small,
                      ),
                    ),
                    CircleButton(
                      label: 'play all',
                      icon: AppIcons.play,
                      onTap: () => playTracks(ref, tracks, 0),
                    ),
                    const SizedBox(width: 10),
                    CircleButton(
                      label: 'shuffle',
                      icon: AppIcons.shuffle,
                      onTap: () => playShuffled(ref, tracks),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemExtent: trackTileHeight,
                  itemCount: tracks.length,
                  itemBuilder: (context, i) =>
                      TrackTile(tracks[i], queue: tracks, index: i),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
