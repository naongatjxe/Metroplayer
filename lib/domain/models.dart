import 'package:flutter/foundation.dart';

int _i(Object? v) => (v as num?)?.toInt() ?? 0;
String _s(Object? v) => (v as String?) ?? '';

@immutable
class Track {
  const Track({
    required this.id,
    required this.path,
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
    this.bitDepth = 0,
    this.codec = '',
    this.dateAddedMs = 0,
    this.artKey,
    this.playCount = 0,
    this.lastPlayedMs = 0,
    this.isFavorite = false,
  });

  factory Track.fromMap(Map<String, Object?> m) => Track(
        id: _i(m['id']),
        path: _s(m['path']),
        title: _s(m['title']),
        artist: _s(m['artist']),
        album: _s(m['album']),
        albumArtist: _s(m['album_artist']),
        genre: _s(m['genre']),
        year: _i(m['year']),
        trackNo: _i(m['track_no']),
        discNo: _i(m['disc_no']),
        durationMs: _i(m['duration_ms']),
        bitrate: _i(m['bitrate']),
        sampleRate: _i(m['sample_rate']),
        bitDepth: _i(m['bit_depth']),
        codec: _s(m['codec']),
        dateAddedMs: _i(m['date_added_ms']),
        artKey: m['art_key'] as String?,
        playCount: _i(m['play_count']),
        lastPlayedMs: _i(m['last_played_ms']),
        isFavorite: _i(m['is_favorite']) == 1,
      );

  final int id;
  final String path;
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
  final int bitDepth;
  final String codec;
  final int dateAddedMs;
  final String? artKey;
  final int playCount;
  final int lastPlayedMs;
  final bool isFavorite;

  Duration get duration => Duration(milliseconds: durationMs);
  String get albumArtistOrArtist => albumArtist.isEmpty ? artist : albumArtist;
}

@immutable
class AlbumSummary {
  const AlbumSummary({
    required this.id,
    required this.title,
    required this.artist,
    required this.year,
    required this.trackCount,
    required this.durationMs,
    this.artKey,
  });

  factory AlbumSummary.fromMap(Map<String, Object?> m) => AlbumSummary(
        id: _i(m['id']),
        title: _s(m['title']),
        artist: _s(m['artist']),
        year: _i(m['year']),
        trackCount: _i(m['track_count']),
        durationMs: _i(m['duration_ms']),
        artKey: m['art_key'] as String?,
      );

  /// Id of the first track in the album; used as the album route id.
  final int id;
  final String title;
  final String artist;
  final int year;
  final int trackCount;
  final int durationMs;
  final String? artKey;
}

@immutable
class ArtistSummary {
  const ArtistSummary(
      {required this.name,
      required this.albums,
      required this.tracks,
      this.artKey});

  factory ArtistSummary.fromMap(Map<String, Object?> m) => ArtistSummary(
        name: _s(m['name']),
        albums: _i(m['albums']),
        tracks: _i(m['tracks']),
        artKey: m['art_key'] as String?,
      );

  final String name;
  final int albums;
  final int tracks;
  final String? artKey;
}

@immutable
class PlaylistSummary {
  const PlaylistSummary(
      {required this.id,
      required this.name,
      required this.count,
      required this.durationMs});

  factory PlaylistSummary.fromMap(Map<String, Object?> m) => PlaylistSummary(
        id: _i(m['id']),
        name: _s(m['name']),
        count: _i(m['count']),
        durationMs: _i(m['duration_ms']),
      );

  final int id;
  final String name;
  final int count;
  final int durationMs;
}

@immutable
class PlaylistEntry {
  const PlaylistEntry(this.entryId, this.track);
  final int entryId;
  final Track track;
}

@immutable
class AlbumDetail {
  const AlbumDetail(this.info, this.tracks);
  final AlbumSummary info;
  final List<Track> tracks;
}

@immutable
class SavedQueue {
  const SavedQueue({
    required this.tracks,
    required this.index,
    required this.positionMs,
    required this.shuffle,
    required this.repeat,
  });
  final List<Track> tracks;
  final int index;
  final int positionMs;
  final bool shuffle;
  final int repeat;
}

@immutable
class SearchResults {
  const SearchResults(
      {this.tracks = const [],
      this.artists = const [],
      this.albums = const []});
  final List<Track> tracks;
  final List<ArtistSummary> artists;
  final List<AlbumSummary> albums;
  bool get isEmpty => tracks.isEmpty && artists.isEmpty && albums.isEmpty;
}

@immutable
class DiagnosticEvent {
  const DiagnosticEvent(this.timeMs, this.kind, this.message);
  final int timeMs;
  final String kind;
  final String message;
}
