import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
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
    final sort = ref.watch(settingsProvider.select((s) => s.albumSort));
    return Scaffold(
      backgroundColor: Mt.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(onSort: _sort),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Mt.pad),
              child: Text('albums', style: Mt.header),
            ),
            _SortRow(
              label: _sortLabel(sort),
              view: _view,
              onSort: _sort,
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

  void _setSort(String value) {
    ref.read(settingsProvider.notifier).setAlbumSort(value);
  }

  Future<void> _sort() async {
    final current = ref.read(settingsProvider).albumSort;
    const options = {
      'title': 'Name (A–Z)',
      'title_desc': 'Name (Z–A)',
      'artist': 'Artist',
      'year': 'Year',
      'added': 'Recently added',
    };
    final choice = await showMetroSheet<String>(
      context,
      builder: (c) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SectionLabel('sort albums'),
          for (final e in options.entries)
            SheetItem(
              label: e.value,
              selected: e.key == current,
              onTap: () => Navigator.pop(c, e.key),
            ),
        ],
      ),
    );
    if (choice != null) _setSort(choice);
  }
}

String _sortLabel(String sort) => switch (sort) {
      'title' => 'Name (A–Z)',
      'title_desc' => 'Name (Z–A)',
      'artist' => 'Artist',
      'year' => 'Year',
      'added' => 'Recently added',
      _ => 'Name (A–Z)',
    };

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSort});
  final VoidCallback onSort;

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
            label: 'sort albums a to z',
            size: 44,
            onTap: onSort,
            child: const Text(
              'a–z',
              style:
                  TextStyle(fontFamily: Mt.font, fontSize: 15, color: Mt.text),
            ),
          ),
          const SizedBox(width: 12),
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

class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.label,
    required this.view,
    required this.onSort,
    required this.onView,
  });

  final String label;
  final _AlbumView view;
  final VoidCallback onSort;
  final ValueChanged<_AlbumView> onView;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Mt.pad, 2, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              label: 'sort albums: $label',
              tilt: false,
              onTap: onSort,
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Mt.body.copyWith(
                          fontSize: 17,
                          color: const Color(0xFFCFCFCF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const MetroIcon(AppIcons.chevronDown,
                        size: 18, color: Mt.dim),
                  ],
                ),
              ),
            ),
          ),
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

class _AlbumGrid extends StatelessWidget {
  const _AlbumGrid({required this.albums, required this.size});
  final List<AlbumSummary> albums;
  final _AlbumSize size;

  @override
  Widget build(BuildContext context) {
    final cross = switch (size) {
      _AlbumSize.large => 2,
      _AlbumSize.medium => 3,
      _AlbumSize.small => 4,
    };
    final titleSize = switch (size) {
      _AlbumSize.large => 18.0,
      _AlbumSize.medium => 15.0,
      _AlbumSize.small => 13.0,
    };
    final subSize = switch (size) {
      _AlbumSize.large => 15.0,
      _AlbumSize.medium => 13.0,
      _AlbumSize.small => 11.0,
    };
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);

    return LayoutBuilder(
      builder: (context, box) {
        final tileWidth = (box.maxWidth - 48 - (cross - 1) * 12) / cross;
        final caption = titleSize * 1.2 * 2 + subSize * 1.2 + 6;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            mainAxisExtent: tileWidth + 6 + caption * scale + 8,
          ),
          itemCount: albums.length,
          itemBuilder: (context, i) {
            final a = albums[i];
            return Pressable(
              label: '${a.title}, ${a.artist}',
              onTap: () => context.push('/album/${a.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ArtworkCard(artKey: a.artKey),
                  const SizedBox(height: 6),
                  Text(
                    a.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Mt.rowTitle.copyWith(fontSize: titleSize),
                  ),
                  Text(
                    a.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Mt.rowSub.copyWith(fontSize: subSize),
                  ),
                ],
              ),
            );
          },
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
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemExtent: 72 * scale,
      itemCount: albums.length,
      itemBuilder: (context, i) {
        final a = albums[i];
        return Pressable(
          label: '${a.title}, ${a.artist}',
          tilt: false,
          onTap: () => context.push('/album/${a.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Artwork(artKey: a.artKey, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        a.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Mt.rowTitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
    );
  }
}
