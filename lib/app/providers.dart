import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/audio_handler.dart';
import '../data/app_db.dart';
import '../data/lyrics_repository.dart';
import '../domain/models.dart';
import 'settings.dart';

/// Injected in main().
final dbProvider = Provider<AppDb>(
    (ref) => throw UnimplementedError('dbProvider not overridden'));
final prefsProvider = Provider<SharedPreferences>(
    (ref) => throw UnimplementedError('prefsProvider not overridden'));
final artDirProvider = Provider<String>(
    (ref) => throw UnimplementedError('artDirProvider not overridden'));
final audioHandlerProvider = Provider<AppAudioHandler>(
  (ref) => throw UnimplementedError('audioHandlerProvider not overridden'),
);
final lyricsRepositoryProvider = Provider<LyricsRepository>((ref) {
  final repository = LyricsRepository();
  ref.onDispose(repository.close);
  return repository;
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
    (ref) => SettingsNotifier(ref.watch(prefsProvider)));

/// Bumped whenever the library changes so every list reloads.
final libraryVersionProvider = StateProvider<int>((ref) => 0);

void bumpLibrary(Ref ref) => ref.read(libraryVersionProvider.notifier).state++;
void bumpLibraryWidget(WidgetRef ref) =>
    ref.read(libraryVersionProvider.notifier).state++;

// ---------------------------------------------------------------------------
// Library
// ---------------------------------------------------------------------------

final trackCountProvider = FutureProvider<int>((ref) {
  ref.watch(libraryVersionProvider);
  return ref.watch(dbProvider).trackCount();
});

final songsProvider = FutureProvider<List<Track>>((ref) {
  ref.watch(libraryVersionProvider);
  final sort = ref.watch(settingsProvider.select((s) => s.songSort));
  return ref.watch(dbProvider).songs(sort);
});

final albumsProvider = FutureProvider<List<AlbumSummary>>((ref) {
  ref.watch(libraryVersionProvider);
  final sort = ref.watch(settingsProvider.select((s) => s.albumSort));
  final category = ref.watch(settingsProvider.select((s) => s.artistCategory));
  return ref.watch(dbProvider).albums(sort: sort, category: category);
});

final artistsProvider = FutureProvider<List<ArtistSummary>>((ref) {
  ref.watch(libraryVersionProvider);
  final category = ref.watch(settingsProvider.select((s) => s.artistCategory));
  return ref.watch(dbProvider).artists(category);
});

final recentTracksProvider = FutureProvider<List<Track>>((ref) {
  ref.watch(libraryVersionProvider);
  return ref.watch(dbProvider).recentTracks(limit: 100);
});

final favouritesProvider = FutureProvider<List<Track>>((ref) {
  ref.watch(libraryVersionProvider);
  return ref.watch(dbProvider).autoPlaylist('favourites');
});

final playlistsProvider = FutureProvider<List<PlaylistSummary>>((ref) {
  ref.watch(libraryVersionProvider);
  return ref.watch(dbProvider).playlists();
});

final recentHistoryVersionProvider = StreamProvider<int>(
    (ref) => ref.watch(audioHandlerProvider).recentHistoryStream);

final autoPlaylistProvider =
    FutureProvider.family<List<Track>, String>((ref, kind) {
  ref.watch(libraryVersionProvider);
  if (kind == 'recent_played') ref.watch(recentHistoryVersionProvider);
  return ref.watch(dbProvider).autoPlaylist(kind);
});

final albumProvider = FutureProvider.family<AlbumDetail?, int>((ref, id) {
  ref.watch(libraryVersionProvider);
  return ref.watch(dbProvider).albumDetail(id);
});

final playlistEntriesProvider =
    FutureProvider.family<List<PlaylistEntry>, int>((ref, id) {
  ref.watch(libraryVersionProvider);
  return ref.watch(dbProvider).playlistEntries(id);
});

final trackByIdProvider = FutureProvider.family<Track?, int>((ref, id) {
  ref.watch(libraryVersionProvider);
  return ref.watch(dbProvider).trackById(id);
});

class ArtistPageData {
  const ArtistPageData(this.tracks, this.albums);
  final List<Track> tracks;
  final List<AlbumSummary> albums;
}

final artistPageProvider =
    FutureProvider.family<ArtistPageData, String>((ref, name) async {
  ref.watch(libraryVersionProvider);
  final db = ref.watch(dbProvider);
  final category = ref.watch(settingsProvider.select((s) => s.artistCategory));
  final tracks = await db.tracksForArtist(name, category);
  final albums = await db.albums(artist: name, category: category);
  return ArtistPageData(tracks, albums);
});

final searchProvider =
    FutureProvider.family<SearchResults, String>((ref, query) {
  ref.watch(libraryVersionProvider);
  final category = ref.watch(settingsProvider.select((s) => s.artistCategory));
  final q = query.trim();
  if (q.isEmpty) return Future.value(const SearchResults());
  return ref.watch(dbProvider).search(q, category);
});

class SourceInfo {
  const SourceInfo(this.path, this.tracks);
  final String path;
  final int tracks;
}

final sourcesProvider = FutureProvider<List<SourceInfo>>((ref) async {
  ref.watch(libraryVersionProvider);
  final db = ref.watch(dbProvider);
  final paths = await db.sources();
  return [
    for (final p in paths) SourceInfo(p, await db.trackCountUnder(p)),
  ];
});

// ---------------------------------------------------------------------------
// Playback
// ---------------------------------------------------------------------------

final mediaItemProvider = StreamProvider<MediaItem?>(
    (ref) => ref.watch(audioHandlerProvider).mediaItem);

final playbackStateProvider = StreamProvider<PlaybackState>(
    (ref) => ref.watch(audioHandlerProvider).playbackState);

final queueProvider = StreamProvider<List<MediaItem>>(
    (ref) => ref.watch(audioHandlerProvider).queue);

final positionProvider = StreamProvider<Duration>(
    (ref) => ref.watch(audioHandlerProvider).positionStream);

final durationProvider = StreamProvider<Duration?>(
    (ref) => ref.watch(audioHandlerProvider).durationStream);

final currentIndexProvider = StreamProvider<int?>(
    (ref) => ref.watch(audioHandlerProvider).queueIndexStream);

final playingProvider = StreamProvider<bool>(
    (ref) => ref.watch(audioHandlerProvider).playingStream);

/// True while the audio service is actually holding a queue.
final hasQueueProvider = Provider<bool>((ref) {
  final item = ref.watch(mediaItemProvider).valueOrNull;
  return item != null;
});
