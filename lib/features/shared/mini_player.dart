import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pressable.dart';
import 'artwork.dart';

/// Persistent bottom bar. Hidden when nothing is loaded or on the full player.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(mediaItemProvider).valueOrNull;
    if (item == null) return const SizedBox.shrink();
    final artKey = item.extras?['art'] as String?;
    final playing = ref.watch(playingProvider).valueOrNull ?? false;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    final barHeight = 62 + (scale - 1) * 34;

    return Container(
      color: Mt.surface,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _MiniProgress(),
              SizedBox(
                height: barHeight,
                child: Row(
                  children: [
                    Expanded(
                      child: Pressable(
                        label: 'open now playing',
                        tilt: false,
                        onTap: () => context.push('/now-playing'),
                        child: Row(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Artwork(artKey: artKey, size: 46),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'now playing',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: Mt.font,
                                      fontSize: 10,
                                      letterSpacing: 2,
                                      color: context.accent,
                                    ),
                                  ),
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Mt.rowTitle.copyWith(fontSize: 19),
                                  ),
                                  Text(
                                    item.artist ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Mt.rowSub,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Pressable(
                      label: 'previous track',
                      tilt: false,
                      onTap: () =>
                          ref.read(audioHandlerProvider).skipToPrevious(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: MetroIcon(AppIcons.previous,
                            size: 24, color: Mt.text),
                      ),
                    ),
                    CircleButton(
                      label: playing ? 'pause' : 'play',
                      size: 48,
                      iconSize: 20,
                      icon: playing ? AppIcons.pause : AppIcons.play,
                      onTap: () {
                        final h = ref.read(audioHandlerProvider);
                        if (playing) {
                          h.pause();
                        } else {
                          h.play();
                        }
                      },
                    ),
                    Pressable(
                      label: 'next track',
                      tilt: false,
                      onTap: () => ref.read(audioHandlerProvider).skipToNext(),
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(8, 8, 12, 8),
                        child:
                            MetroIcon(AppIcons.next, size: 24, color: Mt.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniProgress extends ConsumerWidget {
  const _MiniProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(positionProvider).valueOrNull ?? Duration.zero;
    final dur = ref.watch(durationProvider).valueOrNull;
    final max = (dur?.inMilliseconds ?? 0).toDouble();
    final value = max <= 0 ? 0.0 : (pos.inMilliseconds / max).clamp(0.0, 1.0);
    return LinearProgressIndicator(
      value: value,
      minHeight: 3,
      backgroundColor: Mt.outline,
      color: context.accent,
    );
  }
}
