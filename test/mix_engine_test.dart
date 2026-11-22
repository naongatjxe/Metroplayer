import 'package:flutter_test/flutter_test.dart';
import 'package:metroplayer/domain/mix_engine.dart';
import 'package:metroplayer/domain/models.dart';

Track _track(int id, {String artist = 'artist'}) => Track(
      id: id,
      path: '$id.mp3',
      title: 'song $id',
      artist: artist,
      album: 'album $id',
      genre: id.isEven ? 'rock' : 'jazz',
      year: 2000 + id,
      playCount: id,
    );

void main() {
  test('builds a bounded mix without repeating tracks', () {
    final library = List.generate(5, (index) => _track(index));
    final mix = MixEngine(seed: 1).buildMix(
      library: library,
      length: 10,
    );

    expect(mix, hasLength(5));
    expect(mix.map((track) => track.id).toSet(), hasLength(5));
  });

  test('uses the seed to choose tracks and falls back for a one-track library',
      () {
    final seed = _track(1);
    final other = _track(2);
    final engine = MixEngine(seed: 1);

    expect(
      engine.buildMix(library: [seed, other], seed: seed).map((t) => t.id),
      [other.id],
    );
    expect(engine.buildMix(library: [seed], seed: seed), [seed]);
  });
}
