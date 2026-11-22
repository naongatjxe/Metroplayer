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
import '../shared/track_tile.dart';

class AlbumScreen extends ConsumerWidget {
  const AlbumScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MetroPage(
      label: 'album',
      actions: [
        CircleButton(
          label: 'queue',
          icon: AppIcons.queue,
          size: 44,
          iconSize: 20,
          onTap: () => context.push('/queue'),
        ),
      ],
      child: AsyncView<AlbumDetail?>(
        value: ref.watch(albumProvider(id)),
        onRetry: () => ref.invalidate(albumProvider(id)),
        builder: (detail) => detail == null
            ? const EmptyState(message: 'album not found')
            : _AlbumView(detail),
      ),
    );
  }
}

class _AlbumView extends ConsumerWidget {
  const _AlbumView(this.detail);
  final AlbumDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final album = detail.info;
    final tracks = detail.tracks;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Mt.pad, 8, Mt.pad, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Artwork(artKey: album.artKey, size: 150),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(album.title,
                              style: Mt.itemTitle.copyWith(fontSize: 30)),
                          const SizedBox(height: 6),
                          Text(album.artist, style: Mt.subtitle),
                          const SizedBox(height: 6),
                          Text(
                            '${album.year > 0 ? '${album.year}  ·  ' : ''}'
                            '${album.trackCount} tracks  ·  ${fmtTotal(album.durationMs)}',
                            style: Mt.small,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _RoundFilled(
                      icon: AppIcons.play,
                      label: 'play album',
                      onTap: () => playTracks(ref, tracks, 0),
                    ),
                    const SizedBox(width: 14),
                    CircleButton(
                      label: 'shuffle album',
                      icon: AppIcons.shuffle,
                      onTap: () => playShuffled(ref, tracks),
                    ),
                    const SizedBox(width: 14),
                    CircleButton(
                      label: 'album options',
                      icon: AppIcons.more,
                      onTap: () => showTrackSheet(context, ref, tracks.first),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const SectionLabel('tracks', padding: EdgeInsets.zero),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: tracks.length,
          itemBuilder: (context, i) =>
              TrackTile(tracks[i], queue: tracks, index: i),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _RoundFilled extends StatelessWidget {
  const _RoundFilled(
      {required this.icon, required this.label, required this.onTap});
  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: label,
      onTap: onTap,
      tilt: false,
      child: Container(
        width: 56,
        height: 56,
        decoration:
            BoxDecoration(shape: BoxShape.circle, color: context.accentFill),
        child: Center(child: MetroIcon(icon, size: 24, color: Mt.text)),
      ),
    );
  }
}
