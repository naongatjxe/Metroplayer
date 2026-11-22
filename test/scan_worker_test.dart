import 'package:flutter_test/flutter_test.dart';
import 'package:metroplayer/data/scan_worker.dart';
import 'package:path/path.dart' as p;

void main() {
  test('excludes a folder and its descendants without matching siblings', () {
    final excluded = p.join('library', 'podcasts');

    expect(isPathExcluded(excluded, [excluded]), isTrue);
    expect(
      isPathExcluded(p.join(excluded, 'season 1', 'episode.mp3'), [excluded]),
      isTrue,
    );
    expect(
      isPathExcluded(p.join('library', 'podcasts-old', 'episode.mp3'), [
        excluded,
      ]),
      isFalse,
    );
  });
}
