import 'package:flutter_test/flutter_test.dart';
import 'package:metroplayer/domain/models.dart';
import 'package:metroplayer/features/shared/track_meta.dart';

void main() {
  test('QuickPlay metadata omits format and year', () {
    const track = Track(
      id: 1,
      path: '/music/song.flac',
      title: 'Song',
      artist: 'Artist',
      album: 'Album',
      year: 2024,
      bitrate: 320,
      sampleRate: 48000,
      bitDepth: 24,
      codec: 'flac',
    );

    expect(metaSummary(track), '320 kbps  ·  48.0 kHz  ·  24-bit');
  });
}
