import 'dart:io';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;

import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/equalizer_bars.dart';

/// Album art from the cache folder, with the bundled placeholder on failure.
class Artwork extends ConsumerWidget {
  const Artwork({
    super.key,
    this.artKey,
    this.size,
    this.width,
    this.height,
    this.trackId,
    this.placeholder = AppIcons.albumPlaceholder,
    this.showEqualizer = true,
  });

  final String? artKey;
  final double? size;
  final double? width;
  final double? height;
  final int? trackId;
  final String placeholder;
  final bool showEqualizer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dir = ref.watch(artDirProvider);
    final key = artKey;
    final currentTrackId =
        (ref.watch(mediaItemProvider).valueOrNull?.extras?['tid'] as num?)
            ?.toInt();
    final isCurrentTrack = trackId != null && trackId == currentTrackId;
    final playing =
        isCurrentTrack && (ref.watch(playingProvider).valueOrNull ?? false);
    final w = width ?? size;
    final h = height ?? size;
    return SizedBox(
      width: w,
      height: h,
      child: LayoutBuilder(
        builder: (context, box) {
          final pw = box.maxWidth.isFinite ? box.maxWidth : (w ?? 64);
          final ph = box.maxHeight.isFinite ? box.maxHeight : (h ?? pw);
          final indicatorSize =
              (math.min(pw, ph) * 0.3).clamp(12.0, 32.0).toDouble();
          Widget fallback() => SvgPicture.asset(
                placeholder,
                width: pw,
                height: ph,
                fit: BoxFit.cover,
              );
          final artwork = key == null || key.isEmpty
              ? fallback()
              : Image.file(
                  File(p.join(dir, '${key}_600.jpg')),
                  width: pw,
                  height: ph,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  cacheWidth: (pw * MediaQuery.devicePixelRatioOf(context))
                      .round()
                      .clamp(64, 1400),
                  errorBuilder: (_, __, ___) => fallback(),
                );
          return Stack(
            fit: StackFit.expand,
            children: [
              artwork,
              if (showEqualizer && isCurrentTrack)
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: EqualizerBars(
                        isPlaying: playing,
                        width: indicatorSize,
                        height: indicatorSize,
                        gap: indicatorSize * 0.1,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Square artwork with a thin outline, used for album cards.
class ArtworkCard extends StatelessWidget {
  const ArtworkCard(
      {super.key, this.artKey, this.placeholder = AppIcons.albumPlaceholder});
  final String? artKey;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration:
          BoxDecoration(border: Border.all(color: Mt.outline, width: 1)),
      child: AspectRatio(
        aspectRatio: 1,
        child: Artwork(artKey: artKey, placeholder: placeholder),
      ),
    );
  }
}
