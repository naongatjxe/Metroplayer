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
          if (_items.isEmpty) {
            return const EmptyState(message: 'the queue is empty');
          }
          final startIndex = (current ?? -1) + 1;
          final upcoming = _items.skip(startIndex).toList();
          if (upcoming.isEmpty) {
            return const EmptyState(message: 'no upcoming tracks');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Mt.pad, 0, Mt.pad, 8),
                child: Text(
                    '${upcoming.length} tracks  ·  ${shuffled ? 'shuffled play order' : 'drag to reorder'}',
                    style: Mt.small),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  buildDefaultDragHandles: false,
                  itemCount: upcoming.length,
                  onReorderItem: (oldIndex, newIndex) {
                    if (shuffled) return;
                    setState(() {
                      final from = startIndex + oldIndex;
                      final to = startIndex + newIndex;
                      final item = _items.removeAt(from);
                      _items.insert(to, item);
                    });
                    ref.read(audioHandlerProvider).moveQueueItem(
                        startIndex + oldIndex, startIndex + newIndex);
                  },
                  itemBuilder: (context, i) {
                    final queueIndex = startIndex + i;
                    final item = upcoming[i];
                    final artKey = item.extras?['art'] as String?;
                    return SizedBox(
                      key: ValueKey('${item.id}-$queueIndex'),
                      height: 72,
                      child: Pressable(
                        label: '${item.title}, ${item.artist ?? ''}',
                        tilt: false,
                        onTap: () => ref
                            .read(audioHandlerProvider)
                            .skipToQueueItem(queueIndex),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Artwork(artKey: artKey, size: 52),
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
                                      style: Mt.rowTitle,
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
                              Pressable(
                                label: 'remove from queue',
                                tilt: false,
                                onTap: () {
                                  setState(() => _items = List.of(_items)
                                    ..removeAt(queueIndex));
                                  ref
                                      .read(audioHandlerProvider)
                                      .removeQueueItemAt(queueIndex);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: MetroIcon(AppIcons.close,
                                      size: 18, color: Mt.dim),
                                ),
                              ),
                              if (!shuffled)
                                ReorderableDragStartListener(
                                  index: i,
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: MetroIcon(AppIcons.dragHandle,
                                        size: 20, color: Mt.dim),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
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
