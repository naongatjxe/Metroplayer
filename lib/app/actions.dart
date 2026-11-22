import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/tokens.dart';
import '../core/utils.dart';
import '../core/widgets/controls.dart';
import '../domain/models.dart';
import 'providers.dart';

Future<void> playTracks(
  WidgetRef ref,
  List<Track> tracks,
  int index, {
  bool? shuffle,
}) async {
  if (tracks.isEmpty) return;
  await ref.read(audioHandlerProvider).playTracks(
        tracks,
        index.clamp(0, tracks.length - 1),
        shuffle: shuffle,
      );
}

Future<void> playShuffled(WidgetRef ref, List<Track> tracks) =>
    playTracks(ref, tracks, 0, shuffle: true);

Future<void> toggleFavorite(WidgetRef ref, Track track,
    {BuildContext? context}) async {
  await ref.read(dbProvider).setFavorite(track.id, !track.isFavorite);
  bumpLibraryWidget(ref);
  if (context != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(track.isFavorite
              ? 'removed from favourites'
              : 'added to favourites')),
    );
  }
}

Future<int?> createPlaylistFlow(
  BuildContext context,
  WidgetRef ref, {
  List<int>? addTracks,
}) async {
  final name = await showTextDialog(
    context,
    title: 'new playlist',
    hint: 'name',
    ok: 'create',
  );
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  final db = ref.read(dbProvider);
  final id = await db.createPlaylist(trimmed);
  if (addTracks != null && addTracks.isNotEmpty) {
    await db.addToPlaylist(id, addTracks);
  }
  bumpLibraryWidget(ref);
  return id;
}

Future<void> showPlaylistPicker(
    BuildContext context, WidgetRef ref, List<int> trackIds) async {
  final playlists = await ref.read(dbProvider).playlists();
  if (!context.mounted) return;
  final choice = await showMetroSheet<int>(
    context,
    builder: (c) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionLabel('add to playlist'),
        for (final p in playlists)
          SheetItem(
            label: '${p.name}  ·  ${p.count}',
            onTap: () => Navigator.pop(c, p.id),
          ),
        SheetItem(
          label: '+ new playlist',
          onTap: () => Navigator.pop(c, -1),
        ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return;
  var playlistId = choice;
  if (choice == -1) {
    final id = await createPlaylistFlow(context, ref, addTracks: trackIds);
    if (id == null) return;
    playlistId = id;
  } else {
    await ref.read(dbProvider).addToPlaylist(playlistId, trackIds);
    bumpLibraryWidget(ref);
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('added to playlist')));
  }
}

Future<void> showTrackSheet(
    BuildContext context, WidgetRef ref, Track track) async {
  final action = await showMetroSheet<String>(
    context,
    builder: (c) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Mt.pad, 8, Mt.pad, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(track.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Mt.itemTitle),
              Text(track.artist, style: Mt.subtitle),
            ],
          ),
        ),
        SheetItem(label: 'play next', onTap: () => Navigator.pop(c, 'next')),
        SheetItem(
            label: 'add to queue', onTap: () => Navigator.pop(c, 'queue')),
        SheetItem(
            label: 'add to playlist',
            onTap: () => Navigator.pop(c, 'playlist')),
        SheetItem(
          label:
              track.isFavorite ? 'remove from favourites' : 'add to favourites',
          onTap: () => Navigator.pop(c, 'favourite'),
        ),
        SheetItem(label: 'go to album', onTap: () => Navigator.pop(c, 'album')),
        SheetItem(
            label: 'go to artist', onTap: () => Navigator.pop(c, 'artist')),
      ],
    ),
  );
  if (action == null) return;

  final handler = ref.read(audioHandlerProvider);
  switch (action) {
    case 'next':
      await handler.playNext(track);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('playing next')));
      }
    case 'queue':
      await handler.addToQueue(track);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('added to queue')));
      }
    case 'playlist':
      if (context.mounted) await showPlaylistPicker(context, ref, [track.id]);
    case 'favourite':
      if (context.mounted) await toggleFavorite(ref, track, context: context);
    case 'album':
      final id = await ref.read(dbProvider).albumIdOf(track);
      if (id != null && context.mounted) context.push('/album/$id');
    case 'artist':
      if (context.mounted) context.push('/artist/${encodeName(track.artist)}');
  }
}
