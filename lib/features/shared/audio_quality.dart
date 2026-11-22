import 'package:material_ui/material_ui.dart';

import '../../core/theme/tokens.dart';
import '../../domain/models.dart';
import 'track_meta.dart' as track_meta;

enum QualityTier { lossy, lossless, hiRes, dsd, unknown }

class AudioQuality {
  const AudioQuality({
    required this.format,
    required this.tier,
    this.bitDepth,
    this.sampleRateHz,
    this.bitrateKbps,
  });

  static const _lossy = {
    'mp3',
    'aac',
    'm4a_aac',
    'ogg',
    'opus',
    'wma',
  };
  static const _lossless = {
    'flac',
    'alac',
    'wav',
    'aiff',
    'aif',
    'ape',
    'wv',
  };
  static const _dsd = {'dsf', 'dff'};

  factory AudioQuality.fromTrack(Track track) {
    return AudioQuality.from(
      extensionOrCodec: track.codec,
      bitDepth: track.bitDepth > 0 ? track.bitDepth : null,
      sampleRateHz: track.sampleRate > 0 ? track.sampleRate : null,
      bitrateKbps:
          track.bitrate > 0 ? track_meta.bitrateKbps(track.bitrate) : null,
    );
  }

  factory AudioQuality.from({
    required String extensionOrCodec,
    int? bitDepth,
    int? sampleRateHz,
    int? bitrateKbps,
  }) {
    final format = extensionOrCodec.trim().replaceAll('.', '').toLowerCase();
    final QualityTier tier;
    if (_dsd.contains(format)) {
      tier = QualityTier.dsd;
    } else if (_lossy.contains(format)) {
      tier = QualityTier.lossy;
    } else if (_lossless.contains(format)) {
      tier = (bitDepth ?? 16) >= 24 || (sampleRateHz ?? 44100) > 48000
          ? QualityTier.hiRes
          : QualityTier.lossless;
    } else {
      tier = QualityTier.unknown;
    }

    return AudioQuality(
      format: format.isEmpty ? 'UNKNOWN' : format.toUpperCase(),
      tier: tier,
      bitDepth: bitDepth,
      sampleRateHz: sampleRateHz,
      bitrateKbps: bitrateKbps,
    );
  }

  final String format;
  final QualityTier tier;
  final int? bitDepth;
  final int? sampleRateHz;
  final int? bitrateKbps;

  String get tierLabel => switch (tier) {
        QualityTier.hiRes => 'HI-RES',
        QualityTier.lossless => 'LOSSLESS',
        QualityTier.dsd => 'DSD',
        QualityTier.lossy || QualityTier.unknown => format,
      };

  String get _sampleRateLabel {
    final rate = sampleRateHz;
    if (rate == null || rate <= 0) return '';
    final khz = rate / 1000;
    final value =
        khz == khz.roundToDouble() ? '${khz.toInt()}' : khz.toStringAsFixed(1);
    return '$value kHz';
  }

  String get infoLine {
    final parts = <String>[format];
    final sampleRate = _sampleRateLabel;
    final depth = bitDepth;
    if (depth != null && depth > 0 && sampleRate.isNotEmpty) {
      parts.add('$depth-bit / $sampleRate');
    } else if (sampleRate.isNotEmpty) {
      parts.add(sampleRate);
    }
    final bitrate = bitrateKbps;
    if (bitrate != null && bitrate > 0) {
      parts.add('$bitrate kbps');
    }
    return parts.join(' · ');
  }

  Color accentFor(Color base) => switch (tier) {
        QualityTier.hiRes || QualityTier.dsd => const Color(0xFFF0A30A),
        QualityTier.lossless => base,
        QualityTier.lossy || QualityTier.unknown => Colors.white38,
      };
}

class QualityBadge extends StatelessWidget {
  const QualityBadge({
    super.key,
    required this.quality,
    required this.baseAccent,
    this.showInfoLine = true,
  });

  final AudioQuality quality;
  final Color baseAccent;
  final bool showInfoLine;

  @override
  Widget build(BuildContext context) {
    final color = quality.accentFor(baseAccent);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration:
              BoxDecoration(border: Border.all(color: color, width: 1.2)),
          child: Text(
            quality.tierLabel,
            style: TextStyle(
              color: color,
              fontFamily: Mt.sans,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        if (showInfoLine)
          Text(
            quality.infoLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Mt.small.copyWith(fontSize: 10, color: Colors.white60),
          ),
      ],
    );
  }
}
