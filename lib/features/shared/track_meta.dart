import 'package:audio_service/audio_service.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils.dart';
import '../../domain/models.dart';

/// A label/value pair from a track's tags.
typedef MetaPair = (String label, String value);

/// Tag readers disagree on units: some report kbps, some bits per second.
/// Anything implausibly high is bits/sec, so bring it back to kbps.
int bitrateKbps(int raw) => raw > 10000 ? (raw / 1000).round() : raw;

/// Builds the metadata sheet for the current song. Values that are missing or
/// empty are skipped, so a sparse file still reads cleanly.
List<MetaPair> trackMeta(MediaItem? item, Track? track) {
  final t = track;
  return [
    if ((item?.album ?? '').isNotEmpty) ('album', item!.album!),
    if (t != null && t.albumArtist.isNotEmpty) ('album artist', t.albumArtist),
    if (t != null && t.year > 0) ('year', '${t.year}'),
    if (t != null && t.genre.isNotEmpty) ('genre', t.genre),
    if (t != null && t.trackNo > 0)
      ('track', t.discNo > 0 ? '${t.discNo}.${t.trackNo}' : '${t.trackNo}'),
    if (t != null && t.durationMs > 0) ('length', fmtDur(t.duration)),
    if (t != null && t.codec.isNotEmpty) ('format', t.codec.toUpperCase()),
    if (t != null && t.bitrate > 0)
      ('bitrate', '${bitrateKbps(t.bitrate)} kbps'),
    if (t != null && t.sampleRate > 0)
      ('sample rate', '${(t.sampleRate / 1000).toStringAsFixed(1)} kHz'),
    if (t != null && t.bitDepth > 0) ('bit depth', '${t.bitDepth}-bit'),
    if (t != null && t.playCount > 0) ('plays', '${t.playCount}'),
  ];
}

/// Two-column label/value list, used under the artwork on the start screen.
class TrackMetaList extends StatelessWidget {
  const TrackMetaList({
    super.key,
    this.item,
    this.track,
    this.labelWidth = 92,
    this.limit,
  });

  final MediaItem? item;
  final Track? track;
  final double labelWidth;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    var rows = trackMeta(item, track);
    if (rows.isEmpty) return const SizedBox.shrink();
    if (limit != null && rows.length > limit!) rows = rows.sublist(0, limit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: labelWidth,
                  child: Text(
                    r.$1,
                    style: const TextStyle(
                      fontFamily: Mt.sans,
                      fontSize: 12,
                      height: 1.5,
                      letterSpacing: 0.4,
                      color: Mt.dim,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    r.$2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: Mt.sans,
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFFCFCFCF),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Condensed one-line metadata summary: `flac · 1 411 kbps · 44.1 kHz · 2024`.
String metaSummary(Track? t) {
  if (t == null) return '';
  final parts = <String>[
    if (t.codec.isNotEmpty) t.codec.toUpperCase(),
    if (t.bitrate > 0) '${bitrateKbps(t.bitrate)} kbps',
    if (t.sampleRate > 0) '${(t.sampleRate / 1000).toStringAsFixed(1)} kHz',
    if (t.bitDepth > 0) '${t.bitDepth}-bit',
    if (t.year > 0) '${t.year}',
  ];
  return parts.join('  ·  ');
}
