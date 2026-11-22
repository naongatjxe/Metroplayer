import 'package:flutter/foundation.dart';

@immutable
class LrcLine {
  const LrcLine(this.time, this.text);
  final Duration time;
  final String text;
}

@immutable
class LyricsData {
  const LyricsData(
      {required this.lines, required this.synced, this.plain = ''});
  final List<LrcLine> lines;
  final bool synced;
  final String plain;
}

/// Parses .lrc text: several timestamps per line, [offset:] tag, ignores
/// metadata tags and malformed lines.
abstract final class LrcParser {
  static final _stamp =
      RegExp(r'[\[<](\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?[\]>]');
  static final _offset =
      RegExp(r'^\s*\[offset:\s*([+-]?\d+)\s*\]', caseSensitive: false);
  static final _version = RegExp(r'^v\d+\s*:\s*', caseSensitive: false);
  static final _metadata = RegExp(
    r'^\[(?:ar|al|ti|by|re|ve|length|offset|kana|la|au|tool|id):.*\]$',
    caseSensitive: false,
  );

  static List<LrcLine> parse(String source) {
    final lines =
        source.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    var offsetMs = 0;
    for (final raw in lines) {
      final m = _offset.firstMatch(raw);
      if (m != null) {
        offsetMs = int.tryParse(m.group(1)!) ?? 0;
        break;
      }
    }
    final out = <LrcLine>[];
    for (final raw in lines) {
      var rest = raw.trimLeft().replaceFirst(_version, '');
      final times = <Duration>[];
      while (true) {
        final m = _stamp.matchAsPrefix(rest);
        if (m == null) break;
        final min = int.parse(m.group(1)!);
        final sec = int.parse(m.group(2)!);
        final frac = m.group(3);
        var ms = 0;
        if (frac != null) {
          ms = switch (frac.length) {
            1 => int.parse(frac) * 100,
            2 => int.parse(frac) * 10,
            _ => int.parse(frac),
          };
        }
        final total = (min * 60 + sec) * 1000 + ms - offsetMs;
        times.add(Duration(milliseconds: total < 0 ? 0 : total));
        rest = rest.substring(m.end);
      }
      if (times.isEmpty) continue;
      final text = plainText(rest);
      for (final t in times) {
        out.add(LrcLine(t, text));
      }
    }
    out.sort((a, b) => a.time.compareTo(b.time));
    return out;
  }

  /// Removes LRC timestamps, version labels and metadata for plain display.
  static String plainText(String source) {
    final lines =
        source.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    return lines
        .map((raw) {
          final line = raw.trim().replaceAll(_stamp, '').trim();
          final withoutVersion = line.replaceFirst(_version, '');
          if (_metadata.hasMatch(withoutVersion)) return '';
          return withoutVersion;
        })
        .where((line) => line.isNotEmpty)
        .join('\n');
  }
}
