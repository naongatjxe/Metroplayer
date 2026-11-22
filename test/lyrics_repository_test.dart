import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:metroplayer/data/lyrics_repository.dart';
import 'package:metroplayer/domain/models.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory cacheDirectory;
  late Track track;

  setUp(() async {
    cacheDirectory = await Directory.systemTemp.createTemp('lyrics-cache-');
    track = const Track(
      id: 1,
      path: 'missing.mp3',
      title: 'Example song',
      artist: 'Example artist',
      album: 'Example album',
      durationMs: 120000,
    );
  });

  tearDown(() async {
    if (await cacheDirectory.exists()) {
      await cacheDirectory.delete(recursive: true);
    }
  });

  test('fetches and parses synced lyrics from LRCLIB', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/get');
      expect(request.url.queryParameters['track_name'], 'Example song');
      return http.Response(
        jsonEncode({
          'syncedLyrics': '[00:01.00]first line\n[00:02.00]second line',
          'plainLyrics': null,
          'instrumental': false,
        }),
        200,
      );
    });
    final repository =
        LyricsRepository(client: client, cacheDirectory: cacheDirectory);
    addTearDown(repository.close);

    final lyrics = await repository.get(track);

    expect(lyrics, isNotNull);
    expect(
        lyrics!.lines.map((line) => line.text), ['first line', 'second line']);
  });

  test('uses the search endpoint when exact lookup has no match', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/get') {
        return http.Response('', 404);
      }
      expect(request.url.path, '/api/search');
      return http.Response(
        jsonEncode([
          {
            'syncedLyrics': null,
            'plainLyrics': 'plain lyrics',
            'instrumental': false,
            'duration': 120,
          }
        ]),
        200,
      );
    });
    final repository =
        LyricsRepository(client: client, cacheDirectory: cacheDirectory);
    addTearDown(repository.close);

    final lyrics = await repository.get(track);

    expect(lyrics?.plain, 'plain lyrics');
  });

  test('strips version labels and timestamps from plain API lyrics', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'syncedLyrics': null,
          'plainLyrics': 'v1:\n[00:01.00]first line\n[00:02.00]second line',
          'instrumental': false,
        }),
        200,
      );
    });
    final repository =
        LyricsRepository(client: client, cacheDirectory: cacheDirectory);
    addTearDown(repository.close);

    final lyrics = await repository.get(track);

    expect(
        lyrics?.lines.map((line) => line.text), ['first line', 'second line']);
    expect(lyrics?.plain, isEmpty);
  });

  test('uses a local sidecar before making a network request', () async {
    final path = p.join(cacheDirectory.path, 'song.mp3');
    final sidecar = File(p.setExtension(path, '.lrc'));
    await sidecar.writeAsString('[00:01.00]local lyric');
    final localTrack = Track(
      id: track.id,
      path: path,
      title: track.title,
      artist: track.artist,
      album: track.album,
      durationMs: track.durationMs,
    );
    final client = MockClient((_) async {
      fail('local lyrics should prevent an online lookup');
    });
    final repository =
        LyricsRepository(client: client, cacheDirectory: cacheDirectory);
    addTearDown(repository.close);

    final lyrics = await repository.get(localTrack);

    expect(lyrics?.lines.single.text, 'local lyric');
  });
}
