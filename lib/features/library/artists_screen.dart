import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils.dart';
import '../../core/widgets/alpha_grouped_list.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/metro_page.dart';
import '../../core/widgets/pressable.dart';
import '../../domain/models.dart';
import '../shared/artwork.dart';
import '../shared/async_view.dart';

class ArtistsScreen extends ConsumerWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MetroPage(
      label: 'my library',
      header: 'artists',
      child: AsyncView<List<ArtistSummary>>(
        value: ref.watch(artistsProvider),
        onRetry: () => ref.invalidate(artistsProvider),
        builder: (artists) => artists.isEmpty
            ? const EmptyState(message: 'no artists yet')
            : _ArtistsList(artists),
      ),
    );
  }
}

class _ArtistsList extends StatelessWidget {
  const _ArtistsList(this.artists);
  final List<ArtistSummary> artists;

  @override
  Widget build(BuildContext context) {
    return AlphaGroupedListView<ArtistSummary>(
      items: artists,
      labelOf: (artist) => artist.name,
      itemName: 'artist',
      itemCountLabel: 'artists',
      itemExtent: 72,
      itemBuilder: (context, artist, _, __) => Pressable(
        label: '${artist.name}, ${artist.albums} albums',
        tilt: false,
        onTap: () => context.push('/artist/${encodeName(artist.name)}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Artwork(
                artKey: artist.artKey,
                size: 56,
                placeholder: AppIcons.artistPlaceholder,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Mt.rowTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${artist.albums} albums  ·  ${artist.tracks} tracks',
                      style: Mt.rowSub,
                    ),
                  ],
                ),
              ),
              const MetroIcon(AppIcons.chevronDown, size: 18, color: Mt.faint),
            ],
          ),
        ),
      ),
    );
  }
}
