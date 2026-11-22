import 'dart:math';

import 'models.dart';

enum MixMood { balanced, discover, favorites, chill, energy }

class MixEngine {
  MixEngine({int? seed}) : _random = Random(seed);

  final Random _random;

  List<Track> buildMix({
    required List<Track> library,
    Track? seed,
    int length = 25,
    MixMood mood = MixMood.balanced,
  }) {
    if (library.isEmpty || length <= 0) return [];

    final pool = List<Track>.of(library);
    final mix = <Track>[];
    var current = seed ?? pool[_random.nextInt(pool.length)];
    if (seed == null) {
      mix.add(current);
      pool.removeWhere((track) => track.id == current.id);
    } else {
      pool.removeWhere((track) => track.id == seed.id);
    }

    while (mix.length < length && pool.isNotEmpty) {
      final recent = mix.length >= 6 ? mix.sublist(mix.length - 6) : mix;
      final candidates = <_ScoredTrack>[];
      for (final track in pool) {
        final score = _score(track, current, recent, mood);
        if (score > 0) candidates.add(_ScoredTrack(track, score));
      }
      if (candidates.isEmpty) break;

      current = _weightedPick(candidates);
      mix.add(current);
      pool.removeWhere((track) => track.id == current.id);
    }

    if (mix.isEmpty && seed != null) return [seed];
    return mix;
  }

  double _score(
      Track candidate, Track current, List<Track> recent, MixMood mood) {
    var score = 1.0;
    final artist = candidate.artist.toLowerCase();
    final currentArtist = current.artist.toLowerCase();
    if (artist.isNotEmpty && artist == currentArtist) {
      score *= 0.05;
    } else if (recent.any((track) => track.artist.toLowerCase() == artist)) {
      score *= 0.4;
    }

    final album = candidate.album.toLowerCase();
    if (album.isNotEmpty && album == current.album.toLowerCase()) {
      score *= 0.5;
    }
    if (candidate.genre.isNotEmpty &&
        candidate.genre.toLowerCase() == current.genre.toLowerCase()) {
      score *= 1.6;
    }
    if (candidate.year > 0 && current.year > 0) {
      final gap = (candidate.year - current.year).abs();
      score *= 1.0 + max(0, 10 - gap) / 20;
    }

    final playWeight = switch (mood) {
      MixMood.favorites => 1.5,
      MixMood.discover => 0.2,
      _ => 0.8,
    };
    final favoriteWeight = switch (mood) {
      MixMood.favorites => 3.0,
      MixMood.discover => 1.1,
      _ => 1.8,
    };
    score *= 1.0 + min(candidate.playCount, 30) / 30 * playWeight;
    if (candidate.isFavorite) score *= favoriteWeight;

    if (candidate.lastPlayedMs > 0) {
      final hours = DateTime.now()
          .difference(
              DateTime.fromMillisecondsSinceEpoch(candidate.lastPlayedMs))
          .inHours;
      if (hours >= 0 && hours < 24) score *= 0.4 + hours / 40;
    }

    if (mood == MixMood.discover && candidate.playCount == 0) score *= 2.2;
    if (mood == MixMood.chill) {
      score *= _genreMood(candidate.genre, const [
        'ambient',
        'acoustic',
        'chill',
        'classical',
        'jazz',
        'lo-fi',
        'lofi',
      ])
          ? 1.7
          : 0.8;
    } else if (mood == MixMood.energy) {
      score *= _genreMood(candidate.genre, const [
        'dance',
        'electronic',
        'metal',
        'punk',
        'rock',
        'hip-hop',
        'hip hop',
      ])
          ? 1.7
          : 0.8;
    }

    return score * (0.85 + _random.nextDouble() * 0.3);
  }

  bool _genreMood(String genre, List<String> keywords) {
    final normalized = genre.toLowerCase();
    return keywords.any(normalized.contains);
  }

  Track _weightedPick(List<_ScoredTrack> scored) {
    scored.sort((a, b) => b.score.compareTo(a.score));
    final top = scored.take(12).toList();
    final total = top.fold<double>(0, (sum, item) => sum + item.score);
    var choice = _random.nextDouble() * total;
    for (final item in top) {
      choice -= item.score;
      if (choice <= 0) return item.track;
    }
    return top.last.track;
  }
}

class _ScoredTrack {
  const _ScoredTrack(this.track, this.score);

  final Track track;
  final double score;
}
