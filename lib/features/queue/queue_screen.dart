import 'package:audio_service/audio_service.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/metro_page.dart';
import '../../core/widgets/pressable.dart';
import '../shared/artwork.dart';
import '../shared/async_view.dart';

class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  List<MediaItem> _items = const [];

  bool _same(List<MediaItem> a, List<MediaItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  Future<void> _clear() async {
    final ok = await showConfirm(context, 'clear the queue?', ok: 'clear');
    if (!ok) return;
    await ref.read(audioHandlerProvider).clearQueue();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(queueProvider);
    final current = ref.watch(currentIndexProvider).valueOrNull;
    final mediaItem = ref.watch(mediaItemProvider).valueOrNull;
    final playback = ref.watch(playbackStateProvider).valueOrNull;
    final shuffled = playback?.shuffleMode != AudioServiceShuffleMode.none;

    return MetroPage(
      label: 'queue',
      actions: [
        CircleButton(
          label: 'clear queue',
          icon: AppIcons.delete,
          size: 44,
          iconSize: 20,
          onTap: _clear,
        ),
      ],
      child: AsyncView<List<MediaItem>>(
        value: queue,
        onRetry: () => ref.invalidate(queueProvider),
        builder: (items) {
          if (!_same(items, _items)) _items = List.of(items);
          final currentQueueIndex =
              current != null && current >= 0 && current < _items.length
                  ? current
                  : mediaItem == null
                      ? null
                      : _items.indexWhere((item) => item.id == mediaItem.id);
          final resolvedCurrentIndex =
              currentQueueIndex != null && currentQueueIndex >= 0
                  ? currentQueueIndex
                  : null;
          final currentItem = resolvedCurrentIndex == null
              ? mediaItem
              : _items[resolvedCurrentIndex];
          final startIndex = (resolvedCurrentIndex ?? -1) + 1;
          final upcoming = _items.skip(startIndex).toList();
          if (currentItem == null && _items.isEmpty) {
            return const EmptyState(message: 'the queue is empty');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Mt.pad, 0, Mt.pad, 8),
                child: Text(
                    '${resolvedCurrentIndex ?? 0} played  ·  ${upcoming.length} upcoming  ·  ${shuffled ? 'shuffled play order' : 'drag to reorder'}',
                    style: Mt.small),
              ),
              Expanded(
                child: _items.isEmpty
                    ? currentItem == null
                        ? const EmptyState(message: 'no upcoming tracks')
                        : _QueueTrackRow(
                            key: ValueKey('${currentItem.id}-current'),
                            item: currentItem,
                            isCurrent: true,
                            onTap: () => context.push('/now-playing'),
                          )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        buildDefaultDragHandles: false,
                        itemCount: _items.length,
                        onReorderItem: (oldIndex, newIndex) {
                          if (shuffled ||
                              oldIndex < startIndex ||
                              newIndex < startIndex) {
                            return;
                          }
                          setState(() {
                            final item = _items.removeAt(oldIndex);
                            _items.insert(newIndex, item);
                          });
                          ref
                              .read(audioHandlerProvider)
                              .moveQueueItem(oldIndex, newIndex);
                        },
                        itemBuilder: (context, i) {
                          final item = _items[i];
                          final isCurrent = resolvedCurrentIndex == i;
                          final isUpcoming = i >= startIndex;
                          return _QueueTrackRow(
                            key: ValueKey('${item.id}-$i'),
                            item: item,
                            isCurrent: isCurrent,
                            onTap: isCurrent
                                ? () => context.push('/now-playing')
                                : () => ref
                                    .read(audioHandlerProvider)
                                    .skipToQueueItem(i),
                            onRemove: isUpcoming
                                ? () {
                                    setState(() =>
                                        _items = List.of(_items)..removeAt(i));
                                    ref
                                        .read(audioHandlerProvider)
                                        .removeQueueItemAt(i);
                                  }
                                : null,
                            dragIndex: isUpcoming && !shuffled ? i : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QueueTrackRow extends StatelessWidget {
  const _QueueTrackRow({
    super.key,
    required this.item,
    required this.isCurrent,
    required this.onTap,
    this.onRemove,
    this.dragIndex,
  });

  final MediaItem item;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final int? dragIndex;

  @override
  Widget build(BuildContext context) {
    final trackId = (item.extras?['tid'] as num?)?.toInt();
    final index = dragIndex;
    return SizedBox(
      height: 72,
      child: Pressable(
        label: '${item.title}, ${item.artist ?? ''}',
        tilt: false,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Artwork(
                artKey: item.extras?['art'] as String?,
                size: 52,
                trackId: trackId,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Mt.rowTitle.copyWith(
                        color: isCurrent ? context.accent : Mt.text,
                      ),
                    ),
                    Text(
                      item.artist ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Mt.rowSub,
                    ),
                  ],
                ),
              ),
              if (onRemove != null)
                Pressable(
                  label: 'remove from queue',
                  tilt: false,
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: MetroIcon(AppIcons.close, size: 18, color: Mt.dim),
                  ),
                ),
              if (index != null)
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child:
                        MetroIcon(AppIcons.dragHandle, size: 20, color: Mt.dim),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
