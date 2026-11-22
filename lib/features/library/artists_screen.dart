import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils.dart';
import '../../core/widgets/alpha_scroller.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/metro_page.dart';
import '../../core/widgets/pressable.dart';
import '../../domain/models.dart';
import '../shared/artwork.dart';
import '../shared/async_view.dart';

const double _artistRowHeight = 72;

class ArtistsScreen extends ConsumerWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MetroPage(
      label: 'my library',
      header: 'artists',
      child: AsyncView<List<ArtistSummary>>(
        value: ref.watch(artistsProvider),
        onRetry: () => ref.invalidate(artistsProvider),
        builder: (artists) => artists.isEmpty
            ? const EmptyState(message: 'no artists yet')
            : _ArtistsList(artists),
      ),
    );
  }
}

class _ArtistsList extends StatefulWidget {
  const _ArtistsList(this.artists);
  final List<ArtistSummary> artists;

  @override
  State<_ArtistsList> createState() => _ArtistsListState();
}

class _ArtistsListState extends State<_ArtistsList> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _letters {
    final set = <String>{for (final a in widget.artists) firstLetter(a.name)};
    final letters = set.toList()..sort();
    if (letters.remove('#')) letters.add('#');
    return letters;
  }

  void _jump(String letter) {
    final i = widget.artists.indexWhere((a) => firstLetter(a.name) == letter);
    if (i < 0 || !_controller.hasClients) return;
    _controller.jumpTo((i * _artistRowHeight)
        .clamp(0.0, _controller.position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Mt.pad, 0, Mt.pad, 6),
          child: Text('${widget.artists.length} artists', style: Mt.small),
        ),
        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                controller: _controller,
                itemExtent: _artistRowHeight,
                itemCount: widget.artists.length,
                itemBuilder: (context, i) {
                  final a = widget.artists[i];
                  return Pressable(
                    label: '${a.name}, ${a.albums} albums',
                    tilt: false,
                    onTap: () => context.push('/artist/${encodeName(a.name)}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Artwork(
                            artKey: a.artKey,
                            size: 56,
                            placeholder: AppIcons.artistPlaceholder,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(a.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Mt.rowTitle),
                                const SizedBox(height: 2),
                                Text(
                                  '${a.albums} albums  ·  ${a.tracks} tracks',
                                  style: Mt.rowSub,
                                ),
                              ],
                            ),
                          ),
                          const MetroIcon(AppIcons.chevronDown,
                              size: 18, color: Mt.faint),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 8,
                bottom: 8,
                right: 2,
                child: AlphaScroller(letters: _letters, onLetter: _jump),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
