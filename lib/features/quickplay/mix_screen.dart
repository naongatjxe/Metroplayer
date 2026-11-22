import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/actions.dart';
import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/metro_page.dart';
import '../../core/widgets/pressable.dart';
import '../../domain/mix_engine.dart';
import '../../domain/models.dart';
import '../shared/artwork.dart';
import '../shared/async_view.dart';

class MixScreen extends ConsumerWidget {
  const MixScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(mediaItemProvider).valueOrNull;
    final trackId = (item?.extras?['tid'] as num?)?.toInt();
    final tracks = ref.watch(songsProvider);
    return MetroPage(
      label: 'quickplay',
      header: 'mix',
      child: AsyncView<List<Track>>(
        value: tracks,
        onRetry: () => ref.invalidate(songsProvider),
        builder: (library) => _MixContent(
          key: ValueKey(trackId),
          library: library,
          seed: trackId == null
              ? null
              : library.where((track) => track.id == trackId).firstOrNull,
        ),
      ),
    );
  }
}

class _MixContent extends ConsumerStatefulWidget {
  const _MixContent({
    super.key,
    required this.library,
    required this.seed,
  });

  final List<Track> library;
  final Track? seed;

  @override
  ConsumerState<_MixContent> createState() => _MixContentState();
}

class _MixContentState extends ConsumerState<_MixContent> {
  final _engine = MixEngine();
  MixMood _mood = MixMood.balanced;
  late List<Track> _mix = _buildMix();

  List<Track> _buildMix() => _engine.buildMix(
        library: widget.library,
        seed: widget.seed,
        mood: _mood,
      );

  void _selectMood(MixMood mood) {
    setState(() {
      _mood = mood;
      _mix = _buildMix();
    });
  }

  Future<void> _playMix() async {
    if (_mix.isEmpty) return;
    await playTracks(ref, _mix, 0, shuffle: false);
  }

  @override
  Widget build(BuildContext context) {
    const moods = {
      MixMood.balanced: 'balanced',
      MixMood.discover: 'discover',
      MixMood.favorites: 'favorites',
      MixMood.chill: 'chill',
      MixMood.energy: 'energy',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(Mt.pad, 4, Mt.pad, 24),
      children: [
        const Text('a smart mix built from your library', style: Mt.subtitle),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in moods.entries)
              Pressable(
                label: '${entry.value} mix',
                tilt: false,
                onTap: () => _selectMood(entry.key),
                child: Container(
                  color:
                      _mood == entry.key ? context.accentFill : Mt.surfaceAlt,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Text(
                    entry.value,
                    style: Mt.small.copyWith(
                      color: _mood == entry.key ? Mt.text : Mt.dim,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Pressable(
          label: 'play mix',
          tilt: false,
          onTap: _mix.isEmpty ? null : _playMix,
          child: Container(
            height: 96,
            color: context.accentFill,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _mix.isEmpty ? 'no tracks to mix' : 'play mix',
                        style: Mt.itemTitle.copyWith(fontSize: 24),
                      ),
                      if (_mix.isNotEmpty)
                        Text('${_mix.length} tracks', style: Mt.small),
                    ],
                  ),
                ),
                const MetroIcon(AppIcons.shuffle, size: 32, color: Mt.text),
              ],
            ),
          ),
        ),
        if (_mix.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('up next', style: Mt.label.copyWith(color: context.accent)),
          const SizedBox(height: 8),
          for (var index = 0; index < _mix.length; index++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Pressable(
                label: 'play ${_mix[index].title}',
                tilt: false,
                onTap: () => playTracks(
                  ref,
                  _mix,
                  index,
                  shuffle: false,
                ),
                child: Row(
                  children: [
                    Artwork(
                      artKey: _mix[index].artKey,
                      size: 44,
                      trackId: _mix[index].id,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _mix[index].title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Mt.rowTitle,
                          ),
                          Text(
                            '${_mix[index].artist} · ${_mix[index].album}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Mt.rowSub,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
