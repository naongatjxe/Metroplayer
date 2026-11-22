import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pressable.dart';
import '../shared/async_view.dart';
import '../welcome/welcome_screen.dart';

/// The "music" page: a plain, full-width menu into the library.
///
/// The now-playing column lives on quickplay instead, so this page stays a
/// simple list with no sideways panorama.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(trackCountProvider);
    return Scaffold(
      backgroundColor: Mt.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _HomeHeader(),
            Expanded(
              child: AsyncView<int>(
                value: count,
                onRetry: () => ref.invalidate(trackCountProvider),
                builder: (n) =>
                    n == 0 ? const WelcomeView() : const _MusicMenu(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Mt.pad, 12, Mt.pad, 4),
      child: Row(
        children: [
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'music',
                  maxLines: 1,
                  style: Mt.quickTitle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleButton(
            label: 'quickplay',
            icon: AppIcons.gridView,
            size: 44,
            iconSize: 20,
            onTap: () => context.go('/quickplay'),
          ),
          const SizedBox(width: 10),
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

class _MusicMenu extends ConsumerWidget {
  const _MusicMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(Mt.pad, 24, Mt.pad, 24),
      children: [
        _MenuRow('songs', onTap: () => context.push('/songs')),
        _MenuRow('artists', onTap: () => context.push('/artists')),
        _MenuRow('albums', onTap: () => context.push('/albums')),
        if (settings.showRecent)
          _MenuRow('recently added', onTap: () => context.push('/recent')),
        _MenuRow('playlists', onTap: () => context.push('/playlists')),
        if (settings.showFavourites)
          _MenuRow('favourites', onTap: () => context.push('/auto/favourites')),
        if (settings.showMostPlayed)
          _MenuRow('most played',
              onTap: () => context.push('/auto/most_played')),
        const SizedBox(height: 24),
        _MenuRow(
          'settings',
          color: Mt.dim,
          onTap: () => context.push('/settings'),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.label, {required this.onTap, this.color = Mt.text});
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    return Pressable(
      label: label,
      tilt: false,
      onTap: onTap,
      child: SizedBox(
        height: 54 * scale,
        width: double.infinity,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: Mt.font,
              fontSize: 32,
              height: 1.0,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
