import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// Saves 600 px and 256 px JPEGs named by the hash of the source bytes, so an
/// album's tracks share one file. Returns the art key, or null on failure.
/// Pure Dart: safe inside an isolate.
String? saveArtwork(Uint8List bytes, String artDir) {
  try {
    final key = sha1.convert(bytes).toString();
    final f600 = File(p.join(artDir, '${key}_600.jpg'));
    final f256 = File(p.join(artDir, '${key}_256.jpg'));
    if (f600.existsSync() && f256.existsSync()) return key;
    final src = img.decodeImage(bytes);
    if (src == null) return null;
    final big = src.width > 600
        ? img.copyResize(src,
            width: 600, interpolation: img.Interpolation.average)
        : src;
    final small = img.copyResize(src,
        width: 256, interpolation: img.Interpolation.average);
    f600.writeAsBytesSync(img.encodeJpg(big, quality: 88));
    f256.writeAsBytesSync(img.encodeJpg(small, quality: 85));
    return key;
  } catch (_) {
    return null;
  }
}

const _folderNames = [
  'cover.jpg',
  'cover.png',
  'folder.jpg',
  'folder.png',
  'front.jpg',
  'front.png',
  'album.jpg',
];

/// Looks for cover.jpg, folder.jpg, front.jpg next to the audio file.
String? folderArt(String dirPath, String artDir, Map<String, String?> cache) {
  if (cache.containsKey(dirPath)) return cache[dirPath];
  String? key;
  for (final n in _folderNames) {
    final f = File(p.join(dirPath, n));
    if (f.existsSync()) {
      key = saveArtwork(f.readAsBytesSync(), artDir);
      if (key != null) break;
    }
  }
  cache[dirPath] = key;
  return key;
}
