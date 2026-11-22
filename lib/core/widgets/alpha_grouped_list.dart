import 'package:material_ui/material_ui.dart';

import '../alpha_sort.dart';
import '../theme/tokens.dart';
import 'alpha_jump_dialog.dart';
import 'alpha_scroller.dart';
import 'pressable.dart';

typedef AlphaListItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  int index,
  List<T> orderedItems,
);

class AlphaGroupedListView<T> extends StatefulWidget {
  const AlphaGroupedListView({
    super.key,
    required this.items,
    required this.labelOf,
    required this.itemName,
    required this.itemCountLabel,
    required this.itemExtent,
    required this.itemBuilder,
    this.showCount = true,
    this.showScroller = true,
  });

  final List<T> items;
  final String Function(T) labelOf;
  final String itemName;
  final String itemCountLabel;
  final double itemExtent;
  final AlphaListItemBuilder<T> itemBuilder;
  final bool showCount;
  final bool showScroller;

  @override
  State<AlphaGroupedListView<T>> createState() =>
      _AlphaGroupedListViewState<T>();
}

class _AlphaGroupedListViewState<T> extends State<AlphaGroupedListView<T>> {
  static const double _headerHeight = AlphaLetterHeader.height;

  final _controller = ScrollController();
  late List<AlphaGroup<T>> _groups;
  late List<T> _orderedItems;
  late List<_ListEntry<T>> _entries;
  late Map<String, double> _offsets;

  @override
  void initState() {
    super.initState();
    _rebuildGroups();
  }

  @override
  void didUpdateWidget(covariant AlphaGroupedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items ||
        oldWidget.itemExtent != widget.itemExtent) {
      _rebuildGroups();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rebuildGroups() {
    _groups = groupAlphabetically(widget.items, widget.labelOf);
    _orderedItems = [];
    _entries = [];
    _offsets = {};

    var offset = 0.0;
    for (final group in _groups) {
      _offsets[group.letter] = offset;
      _entries.add(_HeaderEntry(group.letter));
      offset += _headerHeight;
      for (final item in group.items) {
        _entries.add(_ItemEntry(item, _orderedItems.length));
        _orderedItems.add(item);
        offset += widget.itemExtent;
      }
    }
  }

  void _jump(String letter, {bool animate = false}) {
    final offset = _offsets[letter];
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

  Future<void> _openJumpList() async {
    final labels = {
      for (final group in _groups)
        group.letter: group.items.map(widget.labelOf).toList(),
    };
    final letter = await showAlphaJumpDialog(
      context,
      labels: labels,
      itemName: widget.itemName,
    );
    if (letter != null) _jump(letter, animate: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showCount)
          Padding(
            padding: const EdgeInsets.fromLTRB(Mt.pad, 0, Mt.pad, 6),
            child: Text(
              '${_orderedItems.length} ${widget.itemCountLabel}',
              style: Mt.small,
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                controller: _controller,
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: _entries.length,
                itemBuilder: (context, index) => switch (_entries[index]) {
                  _HeaderEntry<T>(:final letter) => AlphaLetterHeader(
                      letter: letter,
                      onTap: _openJumpList,
                    ),
                  _ItemEntry<T>(:final item, :final itemIndex) => SizedBox(
                      height: widget.itemExtent,
                      child: widget.itemBuilder(
                        context,
                        item,
                        itemIndex,
                        _orderedItems,
                      ),
                    ),
                },
              ),
              if (widget.showScroller)
                Positioned(
                  top: 8,
                  bottom: 8,
                  right: 2,
                  child: AlphaScroller(
                    letters: [for (final group in _groups) group.letter],
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

class AlphaLetterHeader extends StatelessWidget {
  const AlphaLetterHeader({
    super.key,
    required this.letter,
    required this.onTap,
  });

  static const double height = 64;

  final String letter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Pressable(
          label: 'jump to $letter',
          tilt: false,
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(left: 18),
            width: 46,
            height: 46,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            color: context.accentFill,
            child: Text(
              letter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w300,
                height: 1,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

sealed class _ListEntry<T> {
  const _ListEntry();
}

final class _HeaderEntry<T> extends _ListEntry<T> {
  const _HeaderEntry(this.letter);

  final String letter;
}

final class _ItemEntry<T> extends _ListEntry<T> {
  const _ItemEntry(this.item, this.itemIndex);

  final T item;
  final int itemIndex;
}
