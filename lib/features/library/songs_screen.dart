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
import '../shared/async_view.dart';
import '../shared/track_tile.dart';

class SongsScreen extends ConsumerWidget {
  const SongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MetroPage(
      label: 'my library',
      header: 'songs',
      actions: [
        CircleButton(
          label: 'search',
          icon: AppIcons.search,
          size: 44,
          iconSize: 20,
          onTap: () => context.push('/search'),
        ),
        CircleButton(
          label: 'sort songs',
          icon: AppIcons.chevronDown,
          size: 44,
          iconSize: 20,
          onTap: () => _sort(context, ref),
        ),
      ],
      child: AsyncView<List<Track>>(
        value: ref.watch(songsProvider),
        onRetry: () => ref.invalidate(songsProvider),
        builder: (songs) => songs.isEmpty
            ? const EmptyState(message: 'no songs yet')
            : _SongsList(songs),
      ),
    );
  }

  Future<void> _sort(BuildContext context, WidgetRef ref) async {
    final current = ref.read(settingsProvider).songSort;
    const options = {
      'title': 'title a–z',
      'title_desc': 'title z–a',
      'artist': 'artist',
      'added': 'newest first',
    };
    final choice = await showMetroSheet<String>(
      context,
      builder: (c) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SectionLabel('sort songs'),
          for (final e in options.entries)
            SheetItem(
              label: e.value,
              selected: e.key == current,
              onTap: () => Navigator.pop(c, e.key),
            ),
        ],
      ),
    );
    if (choice != null) ref.read(settingsProvider.notifier).setSongSort(choice);
  }
}

class _SongsList extends StatefulWidget {
  const _SongsList(this.songs);
  final List<Track> songs;

  @override
  State<_SongsList> createState() => _SongsListState();
}

class _SongsListState extends State<_SongsList> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _letters {
    final set = <String>{for (final t in widget.songs) firstLetter(t.title)};
    final letters = set.toList()..sort();
    if (letters.remove('#')) letters.add('#');
    return letters;
  }

  void _jump(String letter) {
    final i = widget.songs.indexWhere((t) => firstLetter(t.title) == letter);
    if (i < 0 || !_controller.hasClients) return;
    _controller.jumpTo(
        (i * trackTileHeight).clamp(0.0, _controller.position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Mt.pad, 0, Mt.pad, 6),
          child: Text('${widget.songs.length} songs', style: Mt.small),
        ),
        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                controller: _controller,
                itemExtent: trackTileHeight,
                itemCount: widget.songs.length,
                itemBuilder: (context, i) => TrackTile(
                  widget.songs[i],
                  queue: widget.songs,
                  index: i,
                ),
              ),
              Positioned(
                top: 8,
                bottom: 8,
                right: 2,
                child: AlphaScroller(
                  letters: _letters,
                  onLetter: _jump,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
