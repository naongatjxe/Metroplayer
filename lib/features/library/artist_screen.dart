import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/actions.dart';
import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/metro_page.dart';
import '../../core/widgets/pressable.dart';
import '../shared/artwork.dart';
import '../shared/async_view.dart';
import '../shared/track_tile.dart';

class ArtistScreen extends ConsumerWidget {
  const ArtistScreen({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MetroPage(
      label: 'artist',
      child: AsyncView<ArtistPageData>(
        value: ref.watch(artistPageProvider(name)),
        onRetry: () => ref.invalidate(artistPageProvider(name)),
        builder: (data) => data.tracks.isEmpty
            ? const EmptyState(message: 'artist not found')
            : _ArtistView(name: name, data: data),
      ),
    );
  }
}

class _ArtistView extends ConsumerWidget {
  const _ArtistView({required this.name, required this.data});
  final String name;
  final ArtistPageData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artKey = data.albums.isEmpty ? null : data.albums.first.artKey;
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Mt.pad, 8, Mt.pad, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Artwork(
                      artKey: artKey,
                      size: 120,
                      placeholder: AppIcons.artistPlaceholder,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: Mt.itemTitle.copyWith(fontSize: 32)),
                          const SizedBox(height: 6),
                          Text(
                            '${data.albums.length} albums  ·  ${data.tracks.length} tracks',
                            style: Mt.subtitle,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              CircleButton(
                                label: 'play artist',
                                icon: AppIcons.play,
                                onTap: () => playTracks(ref, data.tracks, 0),
                              ),
                              const SizedBox(width: 12),
                              CircleButton(
                                label: 'shuffle artist',
                                icon: AppIcons.shuffle,
                                onTap: () => playShuffled(ref, data.tracks),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (data.albums.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const SectionLabel('albums', padding: EdgeInsets.zero),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 142 + 42 * textScale,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.albums.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final a = data.albums[i];
                        return SizedBox(
                          width: 132,
                          child: Pressable(
                            label: '${a.title} album',
                            onTap: () => context.push('/album/${a.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ArtworkCard(artKey: a.artKey),
                                const SizedBox(height: 6),
                                Text(
                                  a.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Mt.rowSub.copyWith(color: Mt.text),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const SectionLabel('songs', padding: EdgeInsets.zero),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: data.tracks.length,
          itemBuilder: (context, i) =>
              TrackTile(data.tracks[i], queue: data.tracks, index: i),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
