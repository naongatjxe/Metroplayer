import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:path/path.dart' as p;

class TrackTags {
  const TrackTags({
    required this.title,
    required this.artist,
    required this.album,
    this.albumArtist = '',
    this.genre = '',
    this.year = 0,
    this.trackNo = 0,
    this.discNo = 0,
    this.durationMs = 0,
    this.bitrate = 0,
    this.sampleRate = 0,
    this.codec = '',
    this.art,
    this.failed = false,
  });

  final String title;
  final String artist;
  final String album;
  final String albumArtist;
  final String genre;
  final int year;
  final int trackNo;
  final int discNo;
  final int durationMs;
  final int bitrate;
  final int sampleRate;
  final String codec;
  final Uint8List? art;
  final bool failed;
}

String _str(dynamic Function() f) {
  try {
    final v = f();
    if (v == null) return '';
    if (v is List) return v.isEmpty ? '' : v.first.toString().trim();
    return v.toString().trim();
  } catch (_) {
    return '';
  }
}

int _int(dynamic Function() f) {
  try {
    final v = f();
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is DateTime) return v.year;
    if (v is Duration) return v.inMilliseconds;
    return int.tryParse(v.toString().split('/').first.trim()) ?? 0;
  } catch (_) {
    return 0;
  }
}

/// Wraps the tag package. Fields are read through `dynamic` so a renamed field
/// yields an empty value instead of a compile error; check the names against the
/// installed version of audio_metadata_reader and tighten this class.
/// Pure Dart: safe to run inside an isolate. Never throws.
class TagReader {
  const TagReader();

  TrackTags read(File file) {
    final base = p.basenameWithoutExtension(file.path);
    final codec = p.extension(file.path).replaceFirst('.', '').toLowerCase();
    try {
      final dynamic m = readMetadata(file, getImage: true);
      Uint8List? art;
      try {
        final pics = m.pictures;
        if (pics is List && pics.isNotEmpty) {
          final b = pics.first.bytes;
          if (b is Uint8List && b.isNotEmpty) art = b;
        }
      } catch (_) {}
      final title = _str(() => m.title);
      final artist = _str(() => m.artist);
      final album = _str(() => m.album);
      return TrackTags(
        title: title.isEmpty ? base : title,
        artist: artist.isEmpty ? 'unknown artist' : artist,
        album: album.isEmpty ? 'unknown album' : album,
        genre: _str(() => m.genres),
        year: _int(() => m.year),
        trackNo: _int(() => m.trackNumber),
        discNo: _int(() => m.discNumber),
        durationMs: _int(() => m.duration),
        bitrate: _int(() => m.bitrate),
        sampleRate: _int(() => m.sampleRate),
        codec: codec,
        art: art,
      );
    } catch (_) {
      return TrackTags(
        title: base,
        artist: 'unknown artist',
        album: 'unknown album',
        codec: codec,
        failed: true,
      );
    }
  }

  /// Embedded lyrics text, or null.
  String? readLyrics(String path) {
    try {
      final dynamic m = readMetadata(File(path), getImage: false);
      final s = _str(() => m.lyrics);
      return s.isEmpty ? null : s;
    } catch (_) {
      return null;
    }
  }
}
