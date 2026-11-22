import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import 'artwork_cache.dart';
import 'tag_reader.dart';

const audioExtensions = {
  '.mp3',
  '.m4a',
  '.aac',
  '.flac',
  '.wav',
  '.ogg',
  '.opus'
};

class ScanRequest {
  const ScanRequest(this.port, this.roots, this.known, this.artDir);
  final SendPort port;
  final List<String> roots;

  /// path -> modified time (ms) of tracks already in the database.
  final Map<String, int> known;
  final String artDir;
}

/// Runs in a background isolate. Pure Dart only (no plugins). Messages:
/// {t: total, n}, {t: batch, rows}, {t: log, msg}, {t: done, seen}.
Future<void> scanWorker(ScanRequest r) async {
  final seen = <String>[];
  final pending = <(File, int, int)>[];

  Future<void> walk(Directory d) async {
    try {
      if (File(p.join(d.path, '.nomedia')).existsSync()) return;
      await for (final e in d.list(followLinks: false)) {
        if (p.basename(e.path).startsWith('.')) continue;
        if (e is Directory) {
          await walk(e);
        } else if (e is File &&
            audioExtensions.contains(p.extension(e.path).toLowerCase())) {
          try {
            final st = e.statSync();
            final mtime = st.modified.millisecondsSinceEpoch;
            seen.add(e.path);
            if (r.known[e.path] != mtime) pending.add((e, mtime, st.size));
          } catch (_) {}
        }
      }
    } catch (_) {
      r.port.send({'t': 'log', 'msg': 'a folder could not be read'});
    }
  }

  for (final root in r.roots) {
    final d = Directory(root);
    if (d.existsSync()) await walk(d);
  }
  r.port.send({'t': 'total', 'n': pending.length});

  const reader = TagReader();
  final folderCache = <String, String?>{};
  var batch = <Map<String, Object?>>[];
  for (final (file, mtime, size) in pending) {
    final tags = reader.read(file);
    if (tags.failed) {
      r.port.send({'t': 'log', 'msg': 'tags could not be read for a file'});
    }
    var key = tags.art != null ? saveArtwork(tags.art!, r.artDir) : null;
    key ??= folderArt(p.dirname(file.path), r.artDir, folderCache);
    batch.add({
      'path': file.path,
      'title': tags.title,
      'artist': tags.artist,
      'album_artist': tags.albumArtist,
      'album': tags.album,
      'genre': tags.genre,
      'year': tags.year,
      'track_no': tags.trackNo,
      'disc_no': tags.discNo,
      'duration_ms': tags.durationMs,
      'bitrate': tags.bitrate,
      'sample_rate': tags.sampleRate,
      'bit_depth': 0,
      'codec': tags.codec,
      'size_bytes': size,
      'date_modified_ms': mtime,
      'art_key': key,
    });
    if (batch.length >= 50) {
      r.port.send({'t': 'batch', 'rows': batch});
      batch = <Map<String, Object?>>[];
    }
  }
  if (batch.isNotEmpty) r.port.send({'t': 'batch', 'rows': batch});
  r.port.send({'t': 'done', 'seen': seen});
}
