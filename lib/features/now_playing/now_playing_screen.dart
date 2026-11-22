import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/actions.dart';
import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/marquee.dart';
import '../../core/widgets/metro_slider.dart';
import '../../core/widgets/pressable.dart';
import '../../domain/models.dart';
import '../shared/audio_quality.dart';
import '../shared/artwork.dart';
import '../shared/sheets.dart';
import 'now_playing_carousel.dart';
import 'lyrics_tab.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(mediaItemProvider).valueOrNull;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Mt.bg,
        body: item == null
            ? const SafeArea(child: _NothingPlaying())
            : _Player(item: item),
      ),
    );
  }
}

class _NothingPlaying extends StatelessWidget {
  const _NothingPlaying();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Mt.pad, 12, Mt.pad, 8),
            child: CircleButton(
              label: 'close',
              icon: AppIcons.chevronDown,
              size: 44,
              iconSize: 20,
              onTap: () => context.pop(),
            ),
          ),
        ),
        const Expanded(child: EmptyState(message: 'nothing playing')),
      ],
    );
  }
}

class _Player extends ConsumerStatefulWidget {
  const _Player({required this.item});
  final MediaItem item;

  @override
  ConsumerState<_Player> createState() => _PlayerState();
}

class _PlayerState extends ConsumerState<_Player> {
  final PageController _pages = PageController();
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _pages.addListener(_updatePage);
  }

  void _updatePage() {
    final page = _pages.page;
    if (page != null && page != _page) setState(() => _page = page);
  }

  @override
  void dispose() {
    _pages
      ..removeListener(_updatePage)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final queue = ref.watch(queueProvider).valueOrNull ?? const <MediaItem>[];
    final queueIndex = _resolveQueueIndex(
      queue,
      ref.watch(currentIndexProvider).valueOrNull,
      item,
    );
    final tid = (item.extras?['tid'] as num?)?.toInt();
    final track =
        tid == null ? null : ref.watch(trackByIdProvider(tid)).valueOrNull;
    final state = ref.watch(playbackStateProvider).valueOrNull;
    final playing = state?.playing ?? false;
    final shuffleOn =
        state != null && state.shuffleMode != AudioServiceShuffleMode.none;
    final repeatMode = state?.repeatMode ?? AudioServiceRepeatMode.none;
    final repeatOn = repeatMode != AudioServiceRepeatMode.none;
    final artKey = item.extras?['art'] as String?;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _BlurredArtwork(
              key: ValueKey(artKey ?? item.id),
              artKey: artKey,
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Mt.pad, 8, Mt.pad, 4),
                child: Row(
                  children: [
                    CircleButton(
                      label: 'close player',
                      icon: AppIcons.chevronDown,
                      size: 44,
                      iconSize: 20,
                      onTap: () => context.pop(),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text('now playing', style: Mt.topLabel),
                      ),
                    ),
                    CircleButton(
                      label: 'track options',
                      icon: AppIcons.more,
                      size: 44,
                      iconSize: 20,
                      onTap: track == null
                          ? null
                          : () => showTrackSheet(context, ref, track),
                    ),
                  ],
                ),
              ),
              _ArtworkLyricsPivot(page: _page, controller: _pages),
              Expanded(
                child: PageView(
                  controller: _pages,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _ArtworkPage(
                      item: item,
                      track: track,
                      artKey: artKey,
                      playing: playing,
                      shuffleOn: shuffleOn,
                      repeatMode: repeatMode,
                      repeatOn: repeatOn,
                      queue: queue,
                      queueIndex: queueIndex,
                      onSelectQueueItem: (index) =>
                          ref.read(audioHandlerProvider).skipToQueueItem(index),
                      onOpenLyrics: () => _pages.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    LyricsTab(track: track),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

int? _resolveQueueIndex(
  List<MediaItem> queue,
  int? currentIndex,
  MediaItem item,
) {
  if (currentIndex != null &&
      currentIndex >= 0 &&
      currentIndex < queue.length &&
      queue[currentIndex].id == item.id) {
    return currentIndex;
  }
  final index = queue.indexWhere((queuedItem) => queuedItem.id == item.id);
  return index < 0 ? null : index;
}

class _ArtworkLyricsPivot extends StatelessWidget {
  const _ArtworkLyricsPivot({
    required this.page,
    required this.controller,
  });

  final double page;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    const titles = ['artwork', 'lyrics'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(Mt.pad, 10, Mt.pad, 0),
      child: Row(
        children: [
          for (var index = 0; index < titles.length; index++)
            Pressable(
              label: titles[index],
              tilt: false,
              onTap: () => controller.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 24, bottom: 4),
                child: Text(
                  titles[index],
                  style: Mt.quickTitle.copyWith(
                    fontSize: 32,
                    color: Color.lerp(
                      Mt.faint,
                      Mt.text,
                      (1 - (page - index).abs()).clamp(0.0, 1.0).toDouble(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlurredArtwork extends StatelessWidget {
  const _BlurredArtwork({super.key, required this.artKey});

  final String? artKey;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Mt.bg),
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 36,
            sigmaY: 36,
            tileMode: TileMode.decal,
          ),
          child: Artwork(artKey: artKey, showEqualizer: false),
        ),
        const ColoredBox(color: Color(0xB8000000)),
      ],
    );
  }
}

class _ArtworkPage extends ConsumerWidget {
  const _ArtworkPage({
    required this.item,
    required this.track,
    required this.artKey,
    required this.playing,
    required this.shuffleOn,
    required this.repeatMode,
    required this.repeatOn,
    required this.queue,
    required this.queueIndex,
    required this.onSelectQueueItem,
    required this.onOpenLyrics,
  });

  final MediaItem item;
  final Track? track;
  final String? artKey;
  final bool playing;
  final bool shuffleOn;
  final AudioServiceRepeatMode repeatMode;
  final bool repeatOn;
  final List<MediaItem> queue;
  final int? queueIndex;
  final ValueChanged<int> onSelectQueueItem;
  final VoidCallback onOpenLyrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = track;
    final trackId = (item.extras?['tid'] as num?)?.toInt();
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 12, 5, 12),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final artSize = math
                    .min(box.maxWidth, 440.0)
                    .clamp(0.0, box.maxHeight)
                    .toDouble();
                return SizedBox(
                  width: box.maxWidth,
                  height: artSize,
                  child: queueIndex != null && queue.length > 1
                      ? NowPlayingCarousel(
                          currentIndex: queueIndex!,
                          itemCount: queue.length,
                          artworkBuilder: (index) {
                            final queuedItem = queue[index];
                            return Artwork(
                              artKey: queuedItem.extras?['art'] as String?,
                              trackId:
                                  (queuedItem.extras?['tid'] as num?)?.toInt(),
                            );
                          },
                          onIndexChanged: onSelectQueueItem,
                          onTap: onOpenLyrics,
                        )
                      : Center(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onOpenLyrics,
                            child: SizedBox.square(
                              dimension: artSize,
                              child: Artwork(
                                artKey: artKey,
                                trackId: trackId,
                              ),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                Center(
                  child: MarqueeText(
                    item.title,
                    style: Mt.itemTitle.copyWith(fontSize: 20),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.artist ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style:
                      Mt.subtitle.copyWith(fontSize: 14, color: context.accent),
                ),
                if ((item.album ?? '').isNotEmpty)
                  Text(
                    item.album!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Mt.small.copyWith(fontSize: 11),
                  ),
                const SizedBox(height: 6),
                _Progress(track: currentTrack),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Center(
                  child: _ModeButton(
                    icon: AppIcons.shuffle,
                    label: shuffleOn ? 'shuffle on' : 'shuffle off',
                    active: shuffleOn,
                    onTap: () => ref.read(audioHandlerProvider).setShuffleMode(
                          shuffleOn
                              ? AudioServiceShuffleMode.none
                              : AudioServiceShuffleMode.all,
                        ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: CircleButton(
                    label: 'previous track',
                    icon: AppIcons.previous,
                    size: 50,
                    iconSize: 21,
                    onTap: () =>
                        ref.read(audioHandlerProvider).skipToPrevious(),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _PlayButton(
                    playing: playing,
                    onTap: () {
                      final handler = ref.read(audioHandlerProvider);
                      if (playing) {
                        handler.pause();
                      } else {
                        handler.play();
                      }
                    },
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: CircleButton(
                    label: 'next track',
                    icon: AppIcons.next,
                    size: 50,
                    iconSize: 21,
                    onTap: () => ref.read(audioHandlerProvider).skipToNext(),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _ModeButton(
                    icon: repeatMode == AudioServiceRepeatMode.one
                        ? AppIcons.repeatOne
                        : AppIcons.repeat,
                    label: repeatOn ? 'repeat on' : 'repeat off',
                    active: repeatOn,
                    onTap: () {
                      final next = repeatMode == AudioServiceRepeatMode.none
                          ? AudioServiceRepeatMode.all
                          : repeatMode == AudioServiceRepeatMode.all
                              ? AudioServiceRepeatMode.one
                              : AudioServiceRepeatMode.none;
                      ref.read(audioHandlerProvider).setRepeatMode(next);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Center(
                  child: _BottomAction(
                    icon: AppIcons.queue,
                    label: 'queue',
                    onTap: () => context.push('/queue'),
                  ),
                ),
              ),
              const Expanded(child: SizedBox.shrink()),
              const Expanded(child: Center(child: _SleepAction())),
              const Expanded(child: SizedBox.shrink()),
              Expanded(
                child: Center(child: _FavouriteAction(track: track)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Progress extends ConsumerWidget {
  const _Progress({required this.track});

  final Track? track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(positionProvider).valueOrNull ?? Duration.zero;
    final dur = ref.watch(durationProvider).valueOrNull ?? Duration.zero;
    return Column(
      children: [
        MetroSlider(
          value: pos.inMilliseconds.toDouble(),
          max: dur.inMilliseconds.toDouble(),
          onSeek: (v) => ref
              .read(audioHandlerProvider)
              .seek(Duration(milliseconds: v.round())),
        ),
        Row(
          children: [
            Text(fmtDur(pos), style: Mt.small),
            const SizedBox(width: 8),
            if (track case final qualityTrack?)
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: QualityBadge(
                      quality: AudioQuality.fromTrack(qualityTrack),
                      baseAccent: context.accent,
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
            const SizedBox(width: 8),
            Text(fmtDur(dur), style: Mt.small),
          ],
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.playing, required this.onTap});
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: playing ? 'pause' : 'play',
      tilt: false,
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration:
            BoxDecoration(shape: BoxShape.circle, color: context.accentFill),
        child: Center(
          child: MetroIcon(
            playing ? AppIcons.pause : AppIcons.play,
            size: 30,
            color: Mt.text,
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: label,
      tilt: false,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child:
            MetroIcon(icon, size: 20, color: active ? context.accent : Mt.dim),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction(
      {required this.icon,
      required this.label,
      this.onTap,
      this.active = false});
  final String icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: label,
      tilt: false,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MetroIcon(icon, size: 20, color: active ? context.accent : Mt.dim),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style:
                    Mt.small.copyWith(color: active ? context.accent : Mt.dim),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepAction extends ConsumerWidget {
  const _SleepAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.read(audioHandlerProvider);
    return ValueListenableBuilder<Duration?>(
      valueListenable: handler.sleepRemaining,
      builder: (context, left, _) {
        final active = left != null;
        final label = left == null
            ? 'sleep'
            : left == Duration.zero
                ? 'end'
                : '${(left.inSeconds / 60).ceil()} min';
        return _BottomAction(
          icon: active ? AppIcons.sleepTimer : AppIcons.timerOff,
          label: label,
          active: active,
          onTap: () => showSleepTimerSheet(context, ref),
        );
      },
    );
  }
}

class _FavouriteAction extends ConsumerWidget {
  const _FavouriteAction({required this.track});
  final Track? track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favourite = track?.isFavorite ?? false;
    return _BottomAction(
      icon: favourite ? AppIcons.heartFilled : AppIcons.heart,
      label: 'favourite',
      active: favourite,
      onTap: track == null
          ? null
          : () => toggleFavorite(ref, track!, context: context),
    );
  }
}
