import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pressable.dart';
import '../../data/app_log.dart';
import '../../data/lyrics_repository.dart';
import '../../domain/lrc.dart';
import '../../domain/models.dart';

class LyricsTab extends ConsumerStatefulWidget {
  const LyricsTab({super.key, required this.track});

  final Track? track;

  @override
  ConsumerState<LyricsTab> createState() => _LyricsTabState();
}

class _LyricsTabState extends ConsumerState<LyricsTab> {
  TrackLyrics? _lyrics;
  Object? _error;
  bool _loading = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    if (widget.track != null) unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant LyricsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track?.id != widget.track?.id) unawaited(_load());
  }

  Future<void> _load() async {
    final track = widget.track;
    final requestId = ++_requestId;
    if (track == null) {
      setState(() {
        _lyrics = null;
        _error = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _lyrics = null;
      _error = null;
      _loading = true;
    });
    try {
      final lyrics = await ref.read(lyricsRepositoryProvider).get(track);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _lyrics = lyrics;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      AppLog.log('lyrics', 'lyrics lookup failed: ${e.runtimeType}');
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.track == null) {
      return const _LyricsMessage(
        title: 'loading track',
        subtitle: 'lyrics will appear when track details are ready.',
      );
    }
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2, color: Mt.dim),
        ),
      );
    }
    if (_error != null) {
      return _LyricsMessage(
        title: "couldn't load lyrics",
        subtitle: 'check your connection and try again.',
        action: 'try again',
        onAction: _load,
      );
    }

    final lyrics = _lyrics;
    if (lyrics == null) {
      return _LyricsMessage(
        title: 'no lyrics found',
        subtitle: 'no local or online lyrics were found for this track.',
        action: 'try again',
        onAction: _load,
      );
    }
    if (lyrics.instrumental) {
      return const _LyricsMessage(
        title: 'instrumental',
        subtitle: 'no lyrics for this track.',
      );
    }
    if (lyrics.lines.isNotEmpty) {
      return _SyncedLyrics(lines: lyrics.lines);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Mt.pad, 20, Mt.pad, 40),
      child: SelectableText(
        lyrics.plain,
        style: Mt.body.copyWith(fontSize: 20, height: 1.5),
      ),
    );
  }
}

class _SyncedLyrics extends ConsumerStatefulWidget {
  const _SyncedLyrics({required this.lines});

  final List<LrcLine> lines;

  @override
  ConsumerState<_SyncedLyrics> createState() => _SyncedLyricsState();
}

class _SyncedLyricsState extends ConsumerState<_SyncedLyrics> {
  static const _itemHeight = 76.0;
  final _scrollController = ScrollController();
  int _lastIndex = -1;
  DateTime _holdAutoScrollUntil = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _indexAt(Duration position) {
    var low = 0;
    var high = widget.lines.length - 1;
    var result = -1;
    while (low <= high) {
      final middle = (low + high) >> 1;
      if (widget.lines[middle].time <= position) {
        result = middle;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    return result;
  }

  void _scrollTo(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_scrollController.hasClients ||
          index < 0 ||
          DateTime.now().isBefore(_holdAutoScrollUntil)) {
        return;
      }
      final target = (Mt.pad + index * _itemHeight - 120)
          .clamp(0.0, _scrollController.position.maxScrollExtent)
          .toDouble();
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(positionProvider).valueOrNull ?? Duration.zero;
    final activeIndex = _indexAt(position);
    if (activeIndex != _lastIndex) {
      _lastIndex = activeIndex;
      _scrollTo(activeIndex);
    }

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction != ScrollDirection.idle) {
          _holdAutoScrollUntil = DateTime.now().add(const Duration(seconds: 4));
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(Mt.pad, Mt.pad, Mt.pad, 48),
        itemExtent: _itemHeight,
        itemCount: widget.lines.length,
        itemBuilder: (context, index) {
          final line = widget.lines[index];
          final active = index == activeIndex;
          final past = index < activeIndex;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => ref.read(audioHandlerProvider).seek(line.time),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: Mt.body.copyWith(
                  fontSize: active ? 23 : 19,
                  height: 1.2,
                  color: active
                      ? context.accent
                      : past
                          ? Mt.faint
                          : Mt.dim,
                ),
                child: Text(
                  line.text.isEmpty ? '♪' : line.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LyricsMessage extends StatelessWidget {
  const _LyricsMessage({
    required this.title,
    required this.subtitle,
    this.action,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Mt.pad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Mt.itemTitle.copyWith(fontSize: 28)),
            const SizedBox(height: 8),
            Text(subtitle, style: Mt.subtitle),
            if (action != null) ...[
              const SizedBox(height: 18),
              Pressable(
                label: action,
                tilt: false,
                onTap: onAction,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    action!,
                    style: Mt.rowTitle.copyWith(color: context.accent),
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
