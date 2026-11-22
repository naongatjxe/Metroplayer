import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/metro_page.dart';
import '../../core/widgets/pressable.dart';
import '../../domain/models.dart';
import '../shared/artwork.dart';
import '../shared/async_view.dart';
import '../shared/track_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return MetroPage(
      label: 'search',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Mt.pad, 0, Mt.pad, 12),
            child: MetroInput(
              controller: _controller,
              hint: 'songs, albums, artists',
              autofocus: true,
              onChanged: _changed,
              onSubmitted: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? const _SearchHint()
                : AsyncView<SearchResults>(
                    value: ref.watch(searchProvider(_query)),
                    onRetry: () => ref.invalidate(searchProvider(_query)),
                    builder: (results) => results.isEmpty
                        ? const EmptyState(message: 'no results')
                        : _Results(results),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Mt.pad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MetroIcon(AppIcons.search, size: 48, color: Mt.faint),
            const SizedBox(height: 14),
            Text(
              'type to search your library',
              style: Mt.subtitle.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results(this.results);
  final SearchResults results;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (results.tracks.isNotEmpty) ...[
          const SectionLabel('songs',
              padding: EdgeInsets.fromLTRB(Mt.pad, 4, Mt.pad, 4)),
          for (var i = 0; i < results.tracks.length; i++)
            TrackTile(results.tracks[i], queue: results.tracks, index: i),
        ],
        if (results.artists.isNotEmpty) ...[
          const SectionLabel('artists',
              padding: EdgeInsets.fromLTRB(Mt.pad, 18, Mt.pad, 4)),
          for (final a in results.artists)
            SimpleTrackRow(
              title: a.name,
              subtitle: '${a.albums} albums  ·  ${a.tracks} tracks',
              onTap: () => context.push('/artist/${encodeName(a.name)}'),
              trailing: const MetroIcon(AppIcons.chevronDown,
                  size: 18, color: Mt.faint),
            ),
        ],
        if (results.albums.isNotEmpty) ...[
          const SectionLabel('albums',
              padding: EdgeInsets.fromLTRB(Mt.pad, 18, Mt.pad, 4)),
          for (final a in results.albums)
            Pressable(
              label: '${a.title}, ${a.artist}',
              tilt: false,
              onTap: () => context.push('/album/${a.id}'),
              child: SizedBox(
                height: 72,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Artwork(artKey: a.artKey, size: 56),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(a.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Mt.rowTitle),
                            Text('${a.artist}  ·  ${a.trackCount} tracks',
                                style: Mt.rowSub),
                          ],
                        ),
                      ),
                      const MetroIcon(AppIcons.chevronDown,
                          size: 18, color: Mt.faint),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
