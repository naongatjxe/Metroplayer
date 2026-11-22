import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/metro_page.dart';
import '../../domain/models.dart';
import '../shared/async_view.dart';
import '../shared/track_tile.dart';

class RecentScreen extends ConsumerWidget {
  const RecentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MetroPage(
      label: 'my library',
      header: 'recently added',
      headerStyle: Mt.header.copyWith(fontSize: 36),
      child: AsyncView<List<Track>>(
        value: ref.watch(recentTracksProvider),
        onRetry: () => ref.invalidate(recentTracksProvider),
        builder: (tracks) {
          if (tracks.isEmpty) return const EmptyState(message: 'no music yet');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Mt.pad, 0, Mt.pad, 6),
                child: Text('${tracks.length} tracks, newest first',
                    style: Mt.small),
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
