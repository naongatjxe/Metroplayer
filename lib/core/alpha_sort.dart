class AlphaGroup<T> {
  const AlphaGroup(this.letter, this.items);

  final String letter;
  final List<T> items;
}

String alphaSortKey(String value) {
  var text = value.trim().toLowerCase();
  if (text.startsWith('the ')) text = text.substring(4);

  const replacements = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
  };

  return String.fromCharCodes(
    text.runes.map((rune) {
      final character = String.fromCharCode(rune);
      return (replacements[character] ?? character).runes.first;
    }),
  );
}

String alphaGroupLetter(String value) {
  final key = alphaSortKey(value);
  if (key.isEmpty) return '#';
  final first = String.fromCharCode(key.runes.first);
  return RegExp(r'^[a-z]$').hasMatch(first) ? first : '#';
}

List<AlphaGroup<T>> groupAlphabetically<T>(
  Iterable<T> items,
  String Function(T) labelOf, {
  bool hashFirst = false,
}) {
  final sorted = items.toList()
    ..sort((a, b) {
      final byKey =
          alphaSortKey(labelOf(a)).compareTo(alphaSortKey(labelOf(b)));
      if (byKey != 0) return byKey;
      return labelOf(a).compareTo(labelOf(b));
    });

  final grouped = <String, List<T>>{};
  for (final item in sorted) {
    grouped.putIfAbsent(alphaGroupLetter(labelOf(item)), () => []).add(item);
  }

  final letters = grouped.keys.toList()
    ..sort((a, b) {
      if (a == '#') return hashFirst ? -1 : 1;
      if (b == '#') return hashFirst ? 1 : -1;
      return a.compareTo(b);
    });

  return [for (final letter in letters) AlphaGroup(letter, grouped[letter]!)];
}
