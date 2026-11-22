import 'package:audio_service/audio_service.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/actions.dart';
import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/live_tile.dart';
import '../../core/widgets/pressable.dart';
import '../../domain/models.dart';
import '../shared/artwork.dart';
import '../shared/track_meta.dart';
import '../welcome/welcome_screen.dart';

/// Zune-style Quickplay screen: live album-art tiles and a short history.
///
/// Tiles turn over on their own, one at a time, the way Windows Phone live
/// tiles did — the covers come from the whole library, so the wall keeps
/// showing something new without any user input.
class QuickPlayScreen extends ConsumerStatefulWidget {
  const QuickPlayScreen({super.key});

  @override
  ConsumerState<QuickPlayScreen> createState() => _QuickPlayScreenState();
}

class _QuickPlayScreenState extends ConsumerState<QuickPlayScreen> {
  /// Artwork keys in a stable pseudo-random order, rebuilt only when the
  /// library itself changes.
  List<String> _pool = const [];
  String _poolKey = '';

  void _syncPool(Iterable<String?> keys) {
    final unique = <String>{
      for (final k in keys)
        if ((k ?? '').isNotEmpty) k!,
    }.toList()
      ..sort();
    final key = unique.join('|');
    if (key == _poolKey) return;
    _poolKey = key;
    // Deterministic shuffle: same library, same wall, no rebuild flicker.
    var seed = 0;
    for (final k in unique) {
      seed = (seed * 31 + k.hashCode) & 0x7fffffff;
    }
    _pool = unique;
    if (_pool.length > 1) {
      final rng = _Xorshift(seed);
      for (var i = _pool.length - 1; i > 0; i--) {
        final j = rng.next(i + 1);
        final tmp = _pool[i];
        _pool[i] = _pool[j];
        _pool[j] = tmp;
      }
    }
  }

  String? _cover(int slot, int face) {
    if (_pool.isEmpty) return null;
    final n = _pool.length;
    // Walk the shuffled pool by face, stepping far enough between faces that a
    // tile never repeats its own previous cover, and offset per slot so
    // neighbouring tiles show different art whenever the library allows it.
    final i = ((face * 5 + slot) % n + n) % n;
    return _pool[i];
  }

  String? _playlistCover(List<String> covers, int face) =>
      covers.isEmpty ? null : covers[face % covers.length];

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(trackCountProvider).valueOrNull ?? 0;
    final recent =
        ref.watch(autoPlaylistProvider('recent_played')).valueOrNull ??
            const <Track>[];
    final item = ref.watch(mediaItemProvider).valueOrNull;
    final trackId = item?.extras?['tid'];
    final track = trackId is int
        ? ref.watch(trackByIdProvider(trackId)).valueOrNull
        : null;
    final songs = ref.watch(songsProvider).valueOrNull ?? const <Track>[];
    final albums =
        ref.watch(albumsProvider).valueOrNull ?? const <AlbumSummary>[];
    final playlists =
        ref.watch(playlistsProvider).valueOrNull ?? const <PlaylistSummary>[];
    final playlistCovers = <String>[];
    for (final playlist in playlists) {
      final entries =
          ref.watch(playlistEntriesProvider(playlist.id)).valueOrNull ??
              const <PlaylistEntry>[];
      playlistCovers.addAll(
        entries
            .map((entry) => entry.track.artKey)
            .whereType<String>()
            .where((key) => key.isNotEmpty),
      );
    }

    _syncPool([
      for (final t in songs) t.artKey,
      for (final a in albums) a.artKey,
    ]);

    final tiles = <LiveTileSpec>[
      LiveTileSpec(
        id: 'now-playing',
        size: TileSize.wide,
        animate: false,
        label: item == null ? 'browse songs' : 'open now playing',
        onTap: () => context.push(item == null ? '/songs' : '/now-playing'),
        builder: (context, face) => _NowPlayingFace(item: item, track: track),
      ),
      LiveTileSpec(
        id: 'songs',
        size: TileSize.medium,
        animation: TileAnimation.slide,
        label: 'songs',
        onTap: () => context.push('/songs'),
        builder: (context, face) => _TileFace(
          label: 'songs',
          artKey: _cover(0, face),
          tint: const Color(0xFF167C80),
        ),
      ),
      LiveTileSpec(
        id: 'artists',
        size: TileSize.medium,
        label: 'artists',
        onTap: () => context.push('/artists'),
        builder: (context, face) => _TileFace(
          label: 'artists',
          artKey: _cover(1, face),
          tint: const Color(0xFF1B6EC2),
        ),
      ),
      LiveTileSpec(
        id: 'albums',
        size: TileSize.medium,
        animation: TileAnimation.slide,
        label: 'albums',
        onTap: () => context.push('/albums'),
        builder: (context, face) => _TileFace(
          label: 'albums',
          artKey: _cover(2, face),
          tint: const Color(0xFFA8186F),
        ),
      ),
      LiveTileSpec(
        id: 'playlists',
        size: TileSize.medium,
        label: 'playlists',
        onTap: () => context.push('/playlists'),
        builder: (context, face) => _TileFace(
          label: 'playlists',
          artKey: _playlistCover(playlistCovers, face),
          tint: const Color(0xFF1E7B3A),
        ),
      ),
      LiveTileSpec(
        id: 'mix',
        size: TileSize.medium,
        animation: TileAnimation.slide,
        label: 'mix',
        onTap: () => context.push('/mix'),
        builder: (context, face) => _TileFace(
          label: 'mix',
          artKey: _cover(5, face),
          tint: const Color(0xFF6D3AB2),
        ),
      ),
      LiveTileSpec(
        id: 'recent',
        size: TileSize.medium,
        animation: TileAnimation.slide,
        label: 'recently added',
        onTap: () => context.push('/recent'),
        builder: (context, face) => _TileFace(
          label: 'recent',
          artKey: _cover(4, face),
          tint: const Color(0xFF333333),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: Mt.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Mt.pad, 12, Mt.pad, 24),
          children: [
            const _QuickHeader(),
            const SizedBox(height: 20),
            if (count == 0)
              const WelcomeView()
            else ...[
              LiveTileGrid(tiles: tiles, gap: 8),
              const SizedBox(height: 28),
              const Text(
                'history',
                style: TextStyle(
                  fontFamily: Mt.sans,
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF8A8A8A),
                ),
              ),
              const SizedBox(height: 8),
              if (recent.isEmpty)
                const Text('nothing played yet', style: Mt.subtitle)
              else
                for (var i = 0; i < recent.take(6).length; i++)
                  Pressable(
                    label: '${recent[i].title}, ${recent[i].artist}',
                    tilt: false,
                    onTap: () => playTracks(ref, recent, i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        recent[i].title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: Mt.sans,
                          fontSize: 17,
                          height: 1.7,
                          color: Mt.text,
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tiny deterministic RNG so the cover wall is stable for a given library.
class _Xorshift {
  _Xorshift(int seed) : _state = seed == 0 ? 0x9e3779b9 : seed;
  int _state;

  int next(int max) {
    _state ^= (_state << 13) & 0x7fffffff;
    _state ^= _state >> 17;
    _state ^= (_state << 5) & 0x7fffffff;
    _state &= 0x7fffffff;
    return _state % max;
  }
}

class _QuickHeader extends StatelessWidget {
  const _QuickHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleButton(
          label: 'music',
          icon: AppIcons.back,
          size: 44,
          iconSize: 20,
          onTap: () => context.go('/'),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('quickplay', style: Mt.quickTitle),
          ),
        ),
      ],
    );
  }
}

class _TileFace extends StatelessWidget {
  const _TileFace({
    required this.label,
    required this.tint,
    this.artKey,
  });

  final String label;
  final Color tint;
  final String? artKey;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (artKey != null && artKey!.isNotEmpty)
          Artwork(artKey: artKey, showEqualizer: false)
        else
          ColoredBox(color: tint),
        TileShade(color: tint, opacity: 0.28),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: TileCaption(label),
          ),
        ),
      ],
    );
  }
}

class _NowPlayingFace extends StatelessWidget {
  const _NowPlayingFace({this.item, this.track});
  final MediaItem? item;
  final Track? track;

  @override
  Widget build(BuildContext context) {
    final art = item?.extras?['art'] as String?;
    final trackId = (item?.extras?['tid'] as num?)?.toInt();
    final summary = metaSummary(track);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (art != null && art.isNotEmpty)
          Artwork(artKey: art, trackId: trackId, showEqualizer: true)
        else
          ColoredBox(color: context.accentFill),
        TileShade(color: context.accentFill, opacity: 0.45),
        LayoutBuilder(
          builder: (context, box) {
            final inner = box.maxWidth - 28;
            return Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TileCaption(
                    'NOW PLAYING',
                    size: 13,
                    weight: FontWeight.w600,
                  ),
                  const Spacer(),
                  // Scale the tag block down rather than overflow the tile
                  // when the title wraps or the text scale is large.
                  Flexible(
                    flex: 9,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: SizedBox(
                        width: inner,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item?.title ?? 'nothing playing',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: Mt.sans,
                                fontSize: 28,
                                fontWeight: FontWeight.w300,
                                color: Mt.text,
                                shadows: [
                                  Shadow(blurRadius: 4, color: Colors.black),
                                ],
                              ),
                            ),
                            if ((item?.artist ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  item!.artist!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: Mt.sans,
                                    fontSize: 16,
                                    color: context.accent,
                                    shadows: const [
                                      Shadow(
                                          blurRadius: 4, color: Colors.black),
                                    ],
                                  ),
                                ),
                              ),
                            if ((item?.album ?? '').isNotEmpty)
                              Text(
                                item!.album!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: Mt.sans,
                                  fontSize: 14,
                                  color: Color(0xFFCFCFCF),
                                  shadows: [
                                    Shadow(blurRadius: 4, color: Colors.black),
                                  ],
                                ),
                              ),
                            if (summary.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  summary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: Mt.sans,
                                    fontSize: 12,
                                    letterSpacing: 0.3,
                                    color: Mt.dim,
                                    shadows: [
                                      Shadow(
                                          blurRadius: 4, color: Colors.black),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
