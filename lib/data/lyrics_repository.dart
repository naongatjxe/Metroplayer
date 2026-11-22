import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/lrc.dart';
import '../domain/models.dart';
import 'app_log.dart';
import 'tag_reader.dart';

class TrackLyrics {
  const TrackLyrics({
    required this.lines,
    required this.plain,
    required this.instrumental,
    this.syncedText,
  });

  factory TrackLyrics.fromText(String text) {
    final lines = LrcParser.parse(text);
    return TrackLyrics(
      lines: lines,
      plain: lines.isEmpty ? LrcParser.plainText(text) : '',
      instrumental: false,
      syncedText: lines.isEmpty ? null : text,
    );
  }

  factory TrackLyrics.fromApi(Map<String, dynamic> json) {
    final syncedRaw = json['syncedLyrics'];
    final synced = syncedRaw is String ? syncedRaw : null;
    final plainRaw = json['plainLyrics'];
    final plainText = plainRaw is String ? plainRaw : '';
    final syncedLines =
        synced == null ? const <LrcLine>[] : LrcParser.parse(synced);
    final plainLines = syncedLines.isNotEmpty || plainText.isEmpty
        ? const <LrcLine>[]
        : LrcParser.parse(plainText);
    final lines = syncedLines.isNotEmpty ? syncedLines : plainLines;
    final fallbackText = plainText.isNotEmpty ? plainText : (synced ?? '');
    return TrackLyrics(
      lines: lines,
      plain: lines.isEmpty ? LrcParser.plainText(fallbackText) : '',
      instrumental: json['instrumental'] == true,
      syncedText: syncedLines.isNotEmpty
          ? synced
          : plainLines.isNotEmpty
              ? plainText
              : null,
    );
  }

  final List<LrcLine> lines;
  final String plain;
  final bool instrumental;
  final String? syncedText;

  bool get hasLyrics =>
      instrumental || lines.isNotEmpty || plain.trim().isNotEmpty;

  Map<String, Object?> toJson() => {
        'syncedLyrics': syncedText,
        'plainLyrics': plain,
        'instrumental': instrumental,
      };
}

class LyricsRepository {
  LyricsRepository({http.Client? client, Directory? cacheDirectory})
      : _client = client ?? http.Client(),
        _providedCacheDirectory = cacheDirectory;

  static const _host = 'lrclib.net';
  static const _timeout = Duration(seconds: 10);
  static const _headers = {
    'Accept': 'application/json',
    'User-Agent': 'Metroplayer/0.1.0-beta',
  };

  final http.Client _client;
  final Directory? _providedCacheDirectory;
  final Map<String, TrackLyrics> _memoryCache = {};
  Directory? _resolvedCacheDirectory;

  Future<TrackLyrics?> get(Track track) async {
    final local = await _localLyrics(track);
    if (local != null) return local;

    final key = _key(track);
    final cached = _memoryCache[key] ?? await _readCache(key);
    if (cached != null) return cached;

    final json = await _fetch(track);
    if (json == null) return null;

    final lyrics = TrackLyrics.fromApi(json);
    if (!lyrics.hasLyrics) return null;
    _memoryCache[key] = lyrics;
    await _writeCache(key, lyrics);
    return lyrics;
  }

  Future<TrackLyrics?> _localLyrics(Track track) async {
    final sidecar = File(p.setExtension(track.path, '.lrc'));
    try {
      if (await sidecar.exists()) {
        final lyrics = TrackLyrics.fromText(await sidecar.readAsString());
        if (lyrics.hasLyrics) return lyrics;
      }
    } on FileSystemException catch (e) {
      AppLog.log('lyrics', 'could not read sidecar lyrics: ${e.runtimeType}');
    }

    final embedded = const TagReader().readLyrics(track.path);
    if (embedded == null || embedded.trim().isEmpty) return null;
    final lyrics = TrackLyrics.fromText(embedded);
    return lyrics.hasLyrics ? lyrics : null;
  }

  String _key(Track track) => '${track.artist.toLowerCase().trim()}|'
      '${track.title.toLowerCase().trim()}|'
      '${track.album.toLowerCase().trim()}|${track.duration.inSeconds}';

  Future<Directory> _cacheDirectory() async {
    final provided = _providedCacheDirectory;
    if (provided != null) return provided;
    final resolved = _resolvedCacheDirectory;
    if (resolved != null) return resolved;
    final support = await getApplicationSupportDirectory();
    return _resolvedCacheDirectory =
        Directory(p.join(support.path, 'lyrics_cache'));
  }

  Future<TrackLyrics?> _readCache(String key) async {
    try {
      final digest = sha256.convert(utf8.encode(key));
      final file = File(p.join((await _cacheDirectory()).path, '$digest.json'));
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic> || decoded['key'] != key) {
        throw const FormatException('invalid lyrics cache entry');
      }
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        throw const FormatException('invalid lyrics cache data');
      }
      final lyrics = TrackLyrics.fromApi(data);
      if (!lyrics.hasLyrics) return null;
      _memoryCache[key] = lyrics;
      return lyrics;
    } on Exception catch (e) {
      AppLog.log('lyrics', 'could not read lyrics cache: ${e.runtimeType}');
    }
    return null;
  }

  Future<void> _writeCache(String key, TrackLyrics lyrics) async {
    try {
      final digest = sha256.convert(utf8.encode(key));
      final directory = await _cacheDirectory();
      final file = File(p.join(directory.path, '$digest.json'));
      await directory.create(recursive: true);
      await file
          .writeAsString(jsonEncode({'key': key, 'data': lyrics.toJson()}));
    } on Exception catch (e) {
      AppLog.log('lyrics', 'could not save lyrics cache: ${e.runtimeType}');
    }
  }

  Future<Map<String, dynamic>?> _fetch(Track track) async {
    if (track.album.isNotEmpty &&
        track.album.toLowerCase() != 'unknown album' &&
        track.durationMs > 0) {
      final exact = await _getJson('/api/get', {
        'track_name': _clean(track.title),
        'artist_name': _clean(track.artist),
        'album_name': track.album,
        'duration': track.duration.inSeconds.toString(),
      });
      if (exact is Map<String, dynamic> && _hasLyrics(exact)) return exact;
    }

    final byTrack = await _search(
      {'track_name': _clean(track.title), 'artist_name': _clean(track.artist)},
      track,
    );
    if (byTrack != null) return byTrack;

    return _search(
        {'q': '${_clean(track.artist)} ${_clean(track.title)}'}, track);
  }

  Future<Map<String, dynamic>?> _search(
      Map<String, String> query, Track track) async {
    final response = await _getJson('/api/search', query);
    if (response is! List) return null;

    final results = response
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where(_hasLyrics)
        .toList();
    if (results.isEmpty) return null;

    final durationSeconds = track.duration.inMilliseconds / 1000;
    if (durationSeconds > 0) {
      final close = results.where((item) {
        final rawDuration = item['duration'];
        final duration = rawDuration is num ? rawDuration.toDouble() : null;
        return duration != null && (duration - durationSeconds).abs() <= 4;
      }).toList();
      if (close.isNotEmpty) {
        results
          ..clear()
          ..addAll(close);
      }
    }

    int durationDifference(Map<String, dynamic> item) {
      final rawDuration = item['duration'];
      final duration = rawDuration is num ? rawDuration.toDouble() : null;
      if (duration == null || durationSeconds <= 0) return 1 << 30;
      return (duration - durationSeconds).abs().round();
    }

    results.sort((a, b) {
      final syncOrder = (_isSynced(b) ? 1 : 0) - (_isSynced(a) ? 1 : 0);
      return syncOrder != 0
          ? syncOrder
          : durationDifference(a).compareTo(durationDifference(b));
    });
    return results.first;
  }

  Future<dynamic> _getJson(String path, Map<String, String> params) async {
    final uri = Uri.https(_host, path, params);
    final response =
        await _client.get(uri, headers: _headers).timeout(_timeout);
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw HttpException('LRCLIB returned ${response.statusCode}', uri: uri);
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic> || decoded is List) return decoded;
    throw const FormatException('unexpected LRCLIB response');
  }

  bool _hasLyrics(Map<String, dynamic> item) =>
      item['instrumental'] == true ||
      (item['syncedLyrics'] is String &&
          (item['syncedLyrics'] as String).trim().isNotEmpty) ||
      (item['plainLyrics'] is String &&
          (item['plainLyrics'] as String).trim().isNotEmpty);

  bool _isSynced(Map<String, dynamic> item) =>
      item['syncedLyrics'] is String &&
      (item['syncedLyrics'] as String).trim().isNotEmpty;

  String _clean(String value) => value
      .replaceAll(
        RegExp(
          r'\s*[\(\[][^)\]]*(feat|ft\.|remaster|official|lyrics|video|live)[^)\]]*[\)\]]',
          caseSensitive: false,
        ),
        '',
      )
      .trim();

  void close() => _client.close();
}
