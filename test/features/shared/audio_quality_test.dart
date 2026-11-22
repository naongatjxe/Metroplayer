import 'package:flutter_test/flutter_test.dart';
import 'package:metroplayer/domain/models.dart';
import 'package:metroplayer/features/shared/audio_quality.dart';

void main() {
  group('AudioQuality', () {
    test('labels high-resolution lossless tracks', () {
      final quality = AudioQuality.fromTrack(
        const Track(
          id: 1,
          path: '/music/song.flac',
          title: 'Song',
          artist: 'Artist',
          album: 'Album',
          bitDepth: 24,
          sampleRate: 96000,
          bitrate: 4608000,
          codec: 'flac',
        ),
      );

      expect(quality.tierLabel, 'HI-RES');
      expect(quality.infoLine, 'FLAC · 24-bit / 96 kHz · 4608 kbps');
    });

    test('labels regular lossless tracks', () {
      final quality = AudioQuality.fromTrack(
        const Track(
          id: 1,
          path: '/music/song.flac',
          title: 'Song',
          artist: 'Artist',
          album: 'Album',
          sampleRate: 44100,
          codec: 'flac',
        ),
      );

      expect(quality.tierLabel, 'LOSSLESS');
    });

    test('uses the codec label for lossy tracks', () {
      final quality = AudioQuality.fromTrack(
        const Track(
          id: 1,
          path: '/music/song.mp3',
          title: 'Song',
          artist: 'Artist',
          album: 'Album',
          codec: 'mp3',
          bitrate: 320,
        ),
      );

      expect(quality.tierLabel, 'MP3');
      expect(quality.infoLine, 'MP3 · 320 kbps');
    });
  });
}
