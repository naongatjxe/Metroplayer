import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/alpha_sort.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/alpha_grouped_list.dart';
import '../../core/widgets/alpha_jump_dialog.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/pressable.dart';
import '../../domain/models.dart';
import '../shared/artwork.dart';
import '../shared/async_view.dart';

enum _AlbumView { grid, list }

enum _AlbumSize { large, medium, small }

class AlbumsScreen extends ConsumerStatefulWidget {
  const AlbumsScreen({super.key});

  @override
  ConsumerState<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends ConsumerState<AlbumsScreen> {
  _AlbumView _view = _AlbumView.grid;
  _AlbumSize _size = _AlbumSize.large;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mt.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TopBar(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Mt.pad),
              child: Text('albums', style: Mt.header),
            ),
            _ViewRow(
              view: _view,
              onView: (v) => setState(() => _view = v),
            ),
            _SizeRow(
              size: _size,
              onSize: (s) => setState(() => _size = s),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AsyncView<List<AlbumSummary>>(
                value: ref.watch(albumsProvider),
                onRetry: () => ref.invalidate(albumsProvider),
                builder: (albums) {
                  if (albums.isEmpty) {
                    return const EmptyState(message: 'no albums yet');
                  }
                  return _view == _AlbumView.grid
                      ? _AlbumGrid(albums: albums, size: _size)
                      : _AlbumList(albums: albums);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Mt.pad, 12, Mt.pad, 8),
      child: Row(
        children: [
          CircleButton(
            label: 'back',
            icon: AppIcons.back,
            size: 44,
            iconSize: 20,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text('my library', style: Mt.topLabel),
          ),
          CircleButton(
            label: 'search',
            icon: AppIcons.search,
            size: 44,
            iconSize: 20,
            onTap: () => context.push('/search'),
          ),
        ],
      ),
    );
  }
}

class _ViewRow extends StatelessWidget {
  const _ViewRow({
    required this.view,
    required this.onView,
  });

  final _AlbumView view;
  final ValueChanged<_AlbumView> onView;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Mt.pad, 2, 16, 0),
      child: Row(
        children: [
          const Spacer(),
          _ViewButton(
            icon: AppIcons.listView,
            label: 'list view',
            selected: view == _AlbumView.list,
            onTap: () => onView(_AlbumView.list),
          ),
          _ViewButton(
            icon: AppIcons.gridView,
            label: 'grid view',
            selected: view == _AlbumView.grid,
            onTap: () => onView(_AlbumView.grid),
          ),
        ],
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: label,
      tilt: false,
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: MetroIcon(
            icon,
            size: 24,
            color: selected ? context.accent : const Color(0xFFCFCFCF),
          ),
        ),
      ),
    );
  }
}

class _SizeRow extends StatelessWidget {
  const _SizeRow({required this.size, required this.onSize});
  final _AlbumSize size;
  final ValueChanged<_AlbumSize> onSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Mt.pad, 0, Mt.pad, 0),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'size',
            style: TextStyle(fontFamily: Mt.font, fontSize: 17, color: Mt.dim),
          ),
          const SizedBox(width: 14),
          for (final s in _AlbumSize.values)
            Pressable(
              label: '${s.name} album tiles',
              tilt: false,
              onTap: () => onSize(s),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: Text(
                  s.name,
                  style: Mt.body.copyWith(
                    fontSize: 17,
                    color: s == size ? context.accent : Mt.dim,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AlbumGrid extends StatefulWidget {
  const _AlbumGrid({required this.albums, required this.size});
  final List<AlbumSummary> albums;
  final _AlbumSize size;

  @override
  State<_AlbumGrid> createState() => _AlbumGridState();
}

class _AlbumGridState extends State<_AlbumGrid> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jump(String letter, Map<String, double> offsets,
      {bool animate = false}) {
    final offset = offsets[letter];
    if (offset == null || !_controller.hasClients) return;
    final destination =
        offset.clamp(0.0, _controller.position.maxScrollExtent).toDouble();
    if (animate) {
      _controller.animateTo(
        destination,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _controller.jumpTo(destination);
    }
  }

  Future<void> _openJumpList(
    List<AlphaGroup<AlbumSummary>> groups,
    Map<String, double> offsets,
  ) async {
    final labels = {
      for (final group in groups)
        group.letter: group.items.map((album) => album.title).toList(),
    };
    final letter = await showAlphaJumpDialog(
      context,
      labels: labels,
      itemName: 'album',
    );
    if (letter != null) _jump(letter, offsets, animate: true);
  }

  @override
  Widget build(BuildContext context) {
    final groups = groupAlphabetically(widget.albums, (album) => album.title);
    final cross = switch (widget.size) {
      _AlbumSize.large => 2,
      _AlbumSize.medium => 3,
      _AlbumSize.small => 4,
    };
    final titleSize = switch (widget.size) {
      _AlbumSize.large => 18.0,
      _AlbumSize.medium => 15.0,
      _AlbumSize.small => 13.0,
    };
    final subSize = switch (widget.size) {
      _AlbumSize.large => 15.0,
      _AlbumSize.medium => 13.0,
      _AlbumSize.small => 11.0,
    };
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);

    return LayoutBuilder(
      builder: (context, box) {
        final tileWidth = (box.maxWidth - 48 - (cross - 1) * 12) / cross;
        final caption = titleSize * 1.2 * 2 + subSize * 1.2 + 6;
        final tileExtent = tileWidth + 6 + caption * scale + 8;
        final offsets = <String, double>{};
        var offset = 0.0;
        for (final group in groups) {
          offsets[group.letter] = offset;
          final rows = (group.items.length + cross - 1) ~/ cross;
          offset += AlphaLetterHeader.height +
              rows * tileExtent +
              (rows - 1) * 16 +
              16;
        }

        return CustomScrollView(
          controller: _controller,
          slivers: [
            for (final group in groups) ...[
              SliverToBoxAdapter(
                child: AlphaLetterHeader(
                  letter: group.letter,
                  onTap: () => _openJumpList(groups, offsets),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cross,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    mainAxisExtent: tileExtent,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final album = group.items[index];
                      return Pressable(
                        label: '${album.title}, ${album.artist}',
                        onTap: () => context.push('/album/${album.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ArtworkCard(artKey: album.artKey),
                            const SizedBox(height: 6),
                            Text(
                              album.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Mt.rowTitle.copyWith(fontSize: titleSize),
                            ),
                            Text(
                              album.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Mt.rowSub.copyWith(fontSize: subSize),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: group.items.length,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _AlbumList extends StatelessWidget {
  const _AlbumList({required this.albums});
  final List<AlbumSummary> albums;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    return AlphaGroupedListView<AlbumSummary>(
      items: albums,
      labelOf: (album) => album.title,
      itemName: 'album',
      itemCountLabel: 'albums',
      itemExtent: 72 * scale,
      showCount: false,
      showScroller: false,
      itemBuilder: (context, album, _, __) => Pressable(
        label: '${album.title}, ${album.artist}',
        tilt: false,
        onTap: () => context.push('/album/${album.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Artwork(artKey: album.artKey, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      album.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Mt.rowTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      album.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Mt.rowSub,
                    ),
                  ],
                ),
              ),
              const MetroIcon(AppIcons.chevronDown, size: 18, color: Mt.faint),
            ],
          ),
        ),
      ),
    );
  }
}
