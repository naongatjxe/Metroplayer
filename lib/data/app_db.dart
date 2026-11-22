import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../domain/models.dart';

const _schema = <String>[
  '''CREATE TABLE tracks(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    path TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    artist TEXT NOT NULL,
    album_artist TEXT NOT NULL DEFAULT '',
    album TEXT NOT NULL,
    genre TEXT NOT NULL DEFAULT '',
    year INTEGER NOT NULL DEFAULT 0,
    track_no INTEGER NOT NULL DEFAULT 0,
    disc_no INTEGER NOT NULL DEFAULT 0,
    duration_ms INTEGER NOT NULL DEFAULT 0,
    bitrate INTEGER NOT NULL DEFAULT 0,
    sample_rate INTEGER NOT NULL DEFAULT 0,
    bit_depth INTEGER NOT NULL DEFAULT 0,
    codec TEXT NOT NULL DEFAULT '',
    size_bytes INTEGER NOT NULL DEFAULT 0,
    date_added_ms INTEGER NOT NULL,
    date_modified_ms INTEGER NOT NULL,
    art_key TEXT,
    play_count INTEGER NOT NULL DEFAULT 0,
    last_played_ms INTEGER NOT NULL DEFAULT 0,
    is_favorite INTEGER NOT NULL DEFAULT 0
  )''',
  'CREATE INDEX idx_tracks_title ON tracks(title COLLATE NOCASE)',
  'CREATE INDEX idx_tracks_artist ON tracks(artist COLLATE NOCASE)',
  'CREATE INDEX idx_tracks_album ON tracks(album COLLATE NOCASE)',
  'CREATE INDEX idx_tracks_added ON tracks(date_added_ms)',
  'CREATE TABLE playlists(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, created_ms INTEGER NOT NULL)',
  '''CREATE TABLE playlist_tracks(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    playlist_id INTEGER NOT NULL,
    track_id INTEGER NOT NULL,
    position INTEGER NOT NULL
  )''',
  'CREATE INDEX idx_pt_playlist ON playlist_tracks(playlist_id, position)',
  'CREATE TABLE sources(id INTEGER PRIMARY KEY AUTOINCREMENT, path TEXT NOT NULL UNIQUE, added_ms INTEGER NOT NULL)',
  'CREATE TABLE queue_items(position INTEGER PRIMARY KEY, track_id INTEGER NOT NULL)',
  '''CREATE TABLE queue_state(
    id INTEGER PRIMARY KEY CHECK (id = 1),
    current_index INTEGER NOT NULL,
    position_ms INTEGER NOT NULL,
    shuffle INTEGER NOT NULL,
    repeat INTEGER NOT NULL
  )''',
  'CREATE TABLE diagnostic_events(id INTEGER PRIMARY KEY AUTOINCREMENT, time_ms INTEGER NOT NULL, kind TEXT NOT NULL, message TEXT NOT NULL)',
];

class AppDb {
  AppDb._(this.db);
  final Database db;

  static Future<AppDb> open() async {
    final path = p.join(await getDatabasesPath(), 'metroplayer.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (d, v) async {
        for (final s in _schema) {
          await d.execute(s);
        }
      },
    );
    return AppDb._(db);
  }

  // ---- helpers ----
  static const _albumArtistExpr = "COALESCE(NULLIF(album_artist,''),artist)";
  static String _artistExpr(String category) =>
      category == 'album' ? _albumArtistExpr : 'artist';

  List<Track> _tracks(List<Map<String, Object?>> rows) =>
      rows.map(Track.fromMap).toList();

  static String _songOrder(String sort) => switch (sort) {
        'title_desc' => 'title COLLATE NOCASE DESC',
        'added' => 'date_added_ms DESC',
        'artist' =>
          'artist COLLATE NOCASE, album COLLATE NOCASE, disc_no, track_no',
        _ => 'title COLLATE NOCASE ASC',
      };

  static String _albumOrder(String sort) => switch (sort) {
        'title_desc' => 'title COLLATE NOCASE DESC',
        'artist' => 'artist COLLATE NOCASE, title COLLATE NOCASE',
        'year' => 'year DESC, title COLLATE NOCASE',
        'added' => 'added DESC',
        _ => 'title COLLATE NOCASE ASC',
      };

  // ---- tracks ----
  Future<int> trackCount() async =>
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM tracks')) ??
      0;

  Future<List<Track>> songs(String sort) async =>
      _tracks(await db.query('tracks', orderBy: _songOrder(sort)));

  Future<List<Track>> recentTracks({int limit = 100}) async => _tracks(await db
      .query('tracks', orderBy: 'date_added_ms DESC, id DESC', limit: limit));

  Future<Track?> trackById(int id) async {
    final r =
        await db.query('tracks', where: 'id=?', whereArgs: [id], limit: 1);
    return r.isEmpty ? null : Track.fromMap(r.first);
  }

  Future<List<Track>> tracksByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final rows = await db.query('tracks', where: 'id IN (${ids.join(',')})');
    final byId = {for (final r in rows) r['id'] as int: Track.fromMap(r)};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!
    ];
  }

  Future<Map<String, (int, int)>> knownTracks() async {
    final rows =
        await db.query('tracks', columns: ['id', 'path', 'date_modified_ms']);
    return {
      for (final r in rows)
        r['path'] as String: (
          r['id'] as int,
          (r['date_modified_ms'] as num).toInt()
        ),
    };
  }

  Future<void> upsertBatch(
      List<Map<String, Object?>> rows, Map<String, int> ids) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      final b = txn.batch();
      for (final r in rows) {
        final id = ids[r['path']];
        if (id == null) {
          b.insert('tracks', {...r, 'date_added_ms': now});
        } else {
          b.update('tracks', r, where: 'id=?', whereArgs: [id]);
        }
      }
      await b.commit(noResult: true);
    });
  }

  /// Removes rows for files that were not seen. Folders that are currently
  /// unreachable (for example an ejected SD card) keep their rows.
  Future<void> deleteMissing(Set<String> seen, List<String> roots) async {
    final reachable = roots.where((r) => Directory(r).existsSync()).toList();
    bool under(String path, List<String> rs) =>
        rs.any((r) => p.isWithin(r, path));
    final rows = await db.query('tracks', columns: ['id', 'path']);
    final dead = <int>[];
    for (final r in rows) {
      final path = r['path'] as String;
      if (!seen.contains(path) &&
          (under(path, reachable) || !under(path, roots))) {
        dead.add(r['id'] as int);
      }
    }
    for (var i = 0; i < dead.length; i += 500) {
      final chunk =
          dead.sublist(i, i + 500 > dead.length ? dead.length : i + 500);
      await db.delete('tracks', where: 'id IN (${chunk.join(',')})');
    }
    if (dead.isNotEmpty) {
      await db.rawDelete(
          'DELETE FROM playlist_tracks WHERE track_id NOT IN (SELECT id FROM tracks)');
      await db.rawDelete(
          'DELETE FROM queue_items WHERE track_id NOT IN (SELECT id FROM tracks)');
    }
  }

  /// Removes every track that lives under [root]. Used when a music folder is
  /// removed from the sources list.
  Future<void> deleteUnder(String root) async {
    final rows = await db.query('tracks', columns: ['id', 'path']);
    final dead = <int>[
      for (final r in rows)
        if (p.isWithin(root, r['path'] as String)) r['id'] as int,
    ];
    for (var i = 0; i < dead.length; i += 500) {
      final chunk =
          dead.sublist(i, i + 500 > dead.length ? dead.length : i + 500);
      await db.delete('tracks', where: 'id IN (${chunk.join(',')})');
    }
    if (dead.isNotEmpty) {
      await db.rawDelete(
          'DELETE FROM playlist_tracks WHERE track_id NOT IN (SELECT id FROM tracks)');
      await db.rawDelete(
          'DELETE FROM queue_items WHERE track_id NOT IN (SELECT id FROM tracks)');
    }
  }

  Future<void> recordPlay(int id) => db.rawUpdate(
        'UPDATE tracks SET play_count=play_count+1, last_played_ms=? WHERE id=?',
        [DateTime.now().millisecondsSinceEpoch, id],
      );

  Future<void> markPlayStarted(int id) => db.rawUpdate(
        'UPDATE tracks SET last_played_ms=? WHERE id=?',
        [DateTime.now().millisecondsSinceEpoch, id],
      );

  Future<void> setFavorite(int id, bool v) =>
      db.update('tracks', {'is_favorite': v ? 1 : 0},
          where: 'id=?', whereArgs: [id]);

  Future<bool> isFavorite(int id) async {
    final r = await db.query('tracks',
        columns: ['is_favorite'], where: 'id=?', whereArgs: [id], limit: 1);
    return r.isNotEmpty && (r.first['is_favorite'] as num) == 1;
  }

  // ---- albums and artists ----

  /// Albums are grouped purely by the album tag, so a record split across
  /// several track artists (a compilation, a feature, a duet) stays one album.
  /// When that happens the display artist becomes "various artists".
  static const _albumGroup = 'LOWER(album)';

  static const _albumArtistLabel =
      "CASE WHEN COUNT(DISTINCT LOWER($_albumArtistExpr)) > 1 "
      "THEN 'various artists' ELSE MIN($_albumArtistExpr) END";

  Future<List<AlbumSummary>> albums(
      {String sort = 'title',
      String? artist,
      String category = 'artist'}) async {
    final where = artist == null
        ? ''
        : 'WHERE LOWER(${_artistExpr(category)}) = LOWER(?)';
    final rows = await db.rawQuery('''
      SELECT MIN(id) AS id, album AS title, $_albumArtistLabel AS artist,
             MAX(year) AS year,
             COUNT(*) AS track_count, SUM(duration_ms) AS duration_ms,
             MAX(art_key) AS art_key,
             MAX(date_added_ms) AS added
      FROM tracks $where
      GROUP BY $_albumGroup
      ORDER BY ${_albumOrder(sort)}
    ''', artist == null ? null : [artist]);
    return rows.map(AlbumSummary.fromMap).toList();
  }

  Future<AlbumDetail?> albumDetail(int id) async {
    final first = await trackById(id);
    if (first == null) return null;
    final rows = await db.query(
      'tracks',
      where: 'LOWER(album)=LOWER(?)',
      whereArgs: [first.album],
      orderBy: 'disc_no, track_no, title COLLATE NOCASE',
    );
    final tracks = _tracks(rows);
    if (tracks.isEmpty) return null;
    final albumArtists = <String>{
      for (final t in tracks)
        if (t.albumArtistOrArtist.isNotEmpty) t.albumArtistOrArtist,
    };
    final info = AlbumSummary(
      id: id,
      title: first.album,
      artist: albumArtists.length > 1
          ? 'various artists'
          : (albumArtists.isEmpty ? first.artist : albumArtists.first),
      year: tracks.map((t) => t.year).fold(0, (a, b) => a > b ? a : b),
      trackCount: tracks.length,
      durationMs: tracks.fold(0, (a, t) => a + t.durationMs),
      artKey: tracks
          .map((t) => t.artKey)
          .firstWhere((k) => k != null, orElse: () => null),
    );
    return AlbumDetail(info, tracks);
  }

  Future<int?> albumIdOf(Track t) async {
    final r = await db.rawQuery(
      'SELECT MIN(id) AS id FROM tracks WHERE LOWER(album)=LOWER(?)',
      [t.album],
    );
    return r.isEmpty ? null : (r.first['id'] as num?)?.toInt();
  }

  Future<List<ArtistSummary>> artists(String category) async {
    final e = _artistExpr(category);
    final rows = await db.rawQuery('''
      SELECT $e AS name, COUNT(DISTINCT LOWER(album)) AS albums, COUNT(*) AS tracks, MAX(art_key) AS art_key
      FROM tracks GROUP BY LOWER($e) ORDER BY name COLLATE NOCASE
    ''');
    return rows.map(ArtistSummary.fromMap).toList();
  }

  Future<List<Track>> tracksForArtist(String name, String category) async =>
      _tracks(await db.query(
        'tracks',
        where: 'LOWER(${_artistExpr(category)}) = LOWER(?)',
        whereArgs: [name],
        orderBy:
            'album COLLATE NOCASE, disc_no, track_no, title COLLATE NOCASE',
      ));

  // ---- search ----
  Future<SearchResults> search(String q, String category) async {
    final like =
        '%${q.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
    const esc = "ESCAPE '\\'";
    final tracks = _tracks(await db.query(
      'tracks',
      where: 'title LIKE ? $esc OR artist LIKE ? $esc OR album LIKE ? $esc',
      whereArgs: [like, like, like],
      orderBy: 'title COLLATE NOCASE',
      limit: 30,
    ));
    final e = _artistExpr(category);
    final artistRows = await db.rawQuery('''
      SELECT $e AS name, COUNT(DISTINCT LOWER(album)) AS albums, COUNT(*) AS tracks, MAX(art_key) AS art_key
      FROM tracks WHERE $e LIKE ? $esc GROUP BY LOWER($e) ORDER BY name COLLATE NOCASE LIMIT 10
    ''', [like]);
    final albumRows = await db.rawQuery('''
      SELECT MIN(id) AS id, album AS title, $_albumArtistLabel AS artist,
             MAX(year) AS year, COUNT(*) AS track_count,
             SUM(duration_ms) AS duration_ms, MAX(art_key) AS art_key
      FROM tracks WHERE album LIKE ? $esc
      GROUP BY $_albumGroup ORDER BY title COLLATE NOCASE LIMIT 10
    ''', [like]);
    return SearchResults(
      tracks: tracks,
      artists: artistRows.map(ArtistSummary.fromMap).toList(),
      albums: albumRows.map(AlbumSummary.fromMap).toList(),
    );
  }

  // ---- playlists ----
  Future<List<PlaylistSummary>> playlists() async {
    final rows = await db.rawQuery('''
      SELECT pl.id AS id, pl.name AS name, COUNT(pt.id) AS count, COALESCE(SUM(t.duration_ms),0) AS duration_ms
      FROM playlists pl
      LEFT JOIN playlist_tracks pt ON pt.playlist_id = pl.id
      LEFT JOIN tracks t ON t.id = pt.track_id
      GROUP BY pl.id ORDER BY pl.name COLLATE NOCASE
    ''');
    return rows.map(PlaylistSummary.fromMap).toList();
  }

  Future<int> createPlaylist(String name) => db.insert('playlists',
      {'name': name, 'created_ms': DateTime.now().millisecondsSinceEpoch});

  Future<void> renamePlaylist(int id, String name) =>
      db.update('playlists', {'name': name}, where: 'id=?', whereArgs: [id]);

  Future<void> deletePlaylist(int id) async {
    await db.delete('playlist_tracks', where: 'playlist_id=?', whereArgs: [id]);
    await db.delete('playlists', where: 'id=?', whereArgs: [id]);
  }

  Future<void> addToPlaylist(int playlistId, List<int> trackIds) async {
    await db.transaction((txn) async {
      final r = await txn.rawQuery(
        'SELECT COALESCE(MAX(position), -1) AS m FROM playlist_tracks WHERE playlist_id=?',
        [playlistId],
      );
      var pos = ((r.first['m'] as num?)?.toInt() ?? -1) + 1;
      final b = txn.batch();
      for (final t in trackIds) {
        b.insert('playlist_tracks',
            {'playlist_id': playlistId, 'track_id': t, 'position': pos++});
      }
      await b.commit(noResult: true);
    });
  }

  Future<List<PlaylistEntry>> playlistEntries(int id) async {
    final rows = await db.rawQuery('''
      SELECT pt.id AS entry_id, t.* FROM playlist_tracks pt
      JOIN tracks t ON t.id = pt.track_id
      WHERE pt.playlist_id = ? ORDER BY pt.position
    ''', [id]);
    return rows
        .map((r) =>
            PlaylistEntry((r['entry_id'] as num).toInt(), Track.fromMap(r)))
        .toList();
  }

  Future<void> removeFromPlaylist(int entryId) =>
      db.delete('playlist_tracks', where: 'id=?', whereArgs: [entryId]);

  Future<void> reorderPlaylist(
      int playlistId, List<int> entryIdsInOrder) async {
    await db.transaction((txn) async {
      final b = txn.batch();
      for (var i = 0; i < entryIdsInOrder.length; i++) {
        b.update('playlist_tracks', {'position': i},
            where: 'id=? AND playlist_id=?',
            whereArgs: [entryIdsInOrder[i], playlistId]);
      }
      await b.commit(noResult: true);
    });
  }

  Future<List<Track>> autoPlaylist(String kind) async {
    final (where, order, limit) = switch (kind) {
      'favourites' => ('is_favorite=1', 'title COLLATE NOCASE', null),
      'most_played' => ('play_count>0', 'play_count DESC', 100),
      'recent_played' => ('last_played_ms>0', 'last_played_ms DESC', 100),
      _ => ('play_count=0', 'title COLLATE NOCASE', 100),
    };
    return _tracks(
        await db.query('tracks', where: where, orderBy: order, limit: limit));
  }

  // ---- sources ----
  Future<List<String>> sources() async {
    final rows = await db.query('sources', orderBy: 'added_ms');
    return rows.map((r) => r['path'] as String).toList();
  }

  Future<void> addSource(String path) => db.insert('sources',
      {'path': path, 'added_ms': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.ignore);

  Future<void> removeSource(String path) =>
      db.delete('sources', where: 'path=?', whereArgs: [path]);

  Future<int> trackCountUnder(String root) async {
    final rows = await db.query('tracks', columns: ['path']);
    return rows.where((r) => p.isWithin(root, r['path'] as String)).length;
  }

  // ---- queue persistence ----
  Future<void> saveQueue(List<int> ids, int index, int positionMs, bool shuffle,
      int repeat) async {
    await db.transaction((txn) async {
      await txn.delete('queue_items');
      final b = txn.batch();
      for (var i = 0; i < ids.length; i++) {
        b.insert('queue_items', {'position': i, 'track_id': ids[i]});
      }
      b.insert(
        'queue_state',
        {
          'id': 1,
          'current_index': index,
          'position_ms': positionMs,
          'shuffle': shuffle ? 1 : 0,
          'repeat': repeat,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await b.commit(noResult: true);
    });
  }

  Future<SavedQueue?> loadQueue() async {
    final st = await db.query('queue_state', where: 'id=1');
    if (st.isEmpty) return null;
    final items = await db.query('queue_items', orderBy: 'position');
    final tracks = await tracksByIds(
        items.map((r) => (r['track_id'] as num).toInt()).toList());
    final s = st.first;
    return SavedQueue(
      tracks: tracks,
      index: (s['current_index'] as num).toInt(),
      positionMs: (s['position_ms'] as num).toInt(),
      shuffle: (s['shuffle'] as num) == 1,
      repeat: (s['repeat'] as num).toInt(),
    );
  }

  // ---- diagnostics ----
  Future<void> addEvent(String kind, String message) async {
    await db.insert('diagnostic_events', {
      'time_ms': DateTime.now().millisecondsSinceEpoch,
      'kind': kind,
      'message': message
    });
    await db.rawDelete(
        'DELETE FROM diagnostic_events WHERE id NOT IN (SELECT id FROM diagnostic_events ORDER BY id DESC LIMIT 500)');
  }

  Future<List<DiagnosticEvent>> events() async {
    final rows = await db.query('diagnostic_events', orderBy: 'id DESC');
    return rows
        .map((r) => DiagnosticEvent((r['time_ms'] as num).toInt(),
            r['kind'] as String, r['message'] as String))
        .toList();
  }

  Future<void> clearEvents() => db.delete('diagnostic_events');
}
