import 'package:flutter_test/flutter_test.dart';
import 'package:metroplayer/core/alpha_sort.dart';

void main() {
  group('groupAlphabetically', () {
    test('ignores case, accents, and a leading "the "', () {
      final groups = groupAlphabetically(
        ['The Beatles', 'Éclair', 'apple', 'the ants'],
        (title) => title,
      );

      expect(
        groups.expand((group) => group.items),
        ['the ants', 'apple', 'The Beatles', 'Éclair'],
      );
      expect(groups.map((group) => group.letter), ['a', 'b', 'e']);
    });

    test('puts numbers and symbols in the final hash group', () {
      final groups = groupAlphabetically(
        ['#song', '2nd song', 'Alpha'],
        (title) => title,
      );

      expect(groups.map((group) => group.letter), ['a', '#']);
      expect(groups.last.items, ['#song', '2nd song']);
    });
  });
}
