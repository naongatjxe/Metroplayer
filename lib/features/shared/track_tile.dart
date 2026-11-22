import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/actions.dart';
import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils.dart';
import '../../core/widgets/pressable.dart';
import '../../domain/models.dart';
import 'artwork.dart';

const double trackTileHeight = 72;

class TrackTile extends ConsumerWidget {
  const TrackTile(
    this.track, {
    super.key,
    this.queue,
    this.index,
    this.showArt = true,
    this.showMore = true,
    this.trailing,
    this.onTap,
  });

  final Track track;
  final List<Track>? queue;
  final int? index;
  final bool showArt;
  final bool showMore;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(mediaItemProvider).valueOrNull;
    final currentId = (current?.extras?['tid'] as num?)?.toInt();
    final playing = ref.watch(playingProvider).valueOrNull ?? false;
    final isCurrent = currentId == track.id;

    return SizedBox(
      height: trackTileHeight,
      child: Pressable(
        label: '${track.title}, ${track.artist}',
        tilt: false,
        onTap: onTap ?? () => playTracks(ref, queue ?? [track], index ?? 0),
        onLongPress: () => showTrackSheet(context, ref, track),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (showArt) ...[
                Artwork(artKey: track.artKey, size: 56),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Mt.rowTitle.copyWith(
                          color: isCurrent ? context.accent : Mt.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${track.artist}  ·  ${fmtDur(track.duration)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Mt.rowSub,
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: MetroIcon(
                    playing ? AppIcons.volume : AppIcons.musicNote,
                    size: 18,
                    color: context.accent,
                  ),
                ),
              if (trailing != null) trailing!,
              if (showMore)
                Pressable(
                  label: 'more options',
                  tilt: false,
                  onTap: () => showTrackSheet(context, ref, track),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: MetroIcon(AppIcons.more, size: 20, color: Mt.dim),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of album/artist results without the more button.
class SimpleTrackRow extends StatelessWidget {
  const SimpleTrackRow(
      {super.key,
      required this.title,
      required this.subtitle,
      this.onTap,
      this.trailing});
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: '$title, $subtitle',
      tilt: false,
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Mt.rowTitle),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Mt.rowSub),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
