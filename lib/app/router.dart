import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/motion/motion.dart';
import '../core/utils.dart';
import '../features/home/home_screen.dart';
import '../features/library/album_screen.dart';
import '../features/library/albums_screen.dart';
import '../features/library/artist_screen.dart';
import '../features/library/artists_screen.dart';
import '../features/library/auto_list_screen.dart';
import '../features/library/recent_screen.dart';
import '../features/library/songs_screen.dart';
import '../features/now_playing/now_playing_screen.dart';
import '../features/playlists/playlist_screen.dart';
import '../features/playlists/playlists_screen.dart';
import '../features/quickplay/mix_screen.dart';
import '../features/quickplay/quickplay_screen.dart';
import '../features/queue/queue_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/about_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/welcome/welcome_screen.dart';
import 'app.dart';
import 'providers.dart';

CustomTransitionPage<void> _turn(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: MotionTokens.turnIn,
    reverseTransitionDuration: MotionTokens.turnOut,
    transitionsBuilder: (context, animation, secondary, child) {
      if (Motion.reduce(context)) return child;
      final curved =
          CurvedAnimation(parent: animation, curve: MotionTokens.curve);
      return AnimatedBuilder(
        animation: curved,
        builder: (context, _) {
          final angle = (1 - curved.value) * 0.10;
          return Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      );
    },
  );
}

CustomTransitionPage<void> _slideUp(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: MotionTokens.slideUp,
    reverseTransitionDuration: MotionTokens.turnOut,
    transitionsBuilder: (context, animation, secondary, child) {
      if (Motion.reduce(context)) return child;
      final curved =
          CurvedAnimation(parent: animation, curve: MotionTokens.curve);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.read(prefsProvider);
  final initialLocation =
      prefs.getBool(welcomeShownPreferenceKey) == true ? '/' : '/welcome';
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(path: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _turn(state, const HomeScreen()),
          ),
          GoRoute(
            path: '/quickplay',
            pageBuilder: (context, state) =>
                _turn(state, const QuickPlayScreen()),
          ),
          GoRoute(
            path: '/mix',
            pageBuilder: (context, state) => _turn(state, const MixScreen()),
          ),
          GoRoute(
            path: '/music',
            pageBuilder: (context, state) => _turn(state, const HomeScreen()),
          ),
          GoRoute(
            path: '/songs',
            pageBuilder: (context, state) => _turn(state, const SongsScreen()),
          ),
          GoRoute(
            path: '/albums',
            pageBuilder: (context, state) => _turn(state, const AlbumsScreen()),
          ),
          GoRoute(
            path: '/artists',
            pageBuilder: (context, state) =>
                _turn(state, const ArtistsScreen()),
          ),
          GoRoute(
            path: '/recent',
            pageBuilder: (context, state) => _turn(state, const RecentScreen()),
          ),
          GoRoute(
            path: '/album/:id',
            pageBuilder: (context, state) => _turn(
              state,
              AlbumScreen(
                  id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
            ),
          ),
          GoRoute(
            path: '/artist/:name',
            pageBuilder: (context, state) => _turn(
              state,
              ArtistScreen(name: _decode(state.pathParameters['name'] ?? '')),
            ),
          ),
          GoRoute(
            path: '/auto/:kind',
            pageBuilder: (context, state) => _turn(
              state,
              AutoListScreen(
                  kind: state.pathParameters['kind'] ?? 'favourites'),
            ),
          ),
          GoRoute(
            path: '/playlists',
            pageBuilder: (context, state) =>
                _turn(state, const PlaylistsScreen()),
          ),
          GoRoute(
            path: '/playlists/:id',
            pageBuilder: (context, state) => _turn(
              state,
              PlaylistScreen(
                  id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => _turn(state, const SearchScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                _turn(state, const SettingsScreen()),
          ),
          GoRoute(
            path: '/about',
            pageBuilder: (context, state) => _turn(state, const AboutScreen()),
          ),
          GoRoute(
            path: '/welcome',
            pageBuilder: (context, state) =>
                _turn(state, const WelcomeScreen()),
          ),
          GoRoute(
            path: '/queue',
            pageBuilder: (context, state) => _turn(state, const QueueScreen()),
          ),
          GoRoute(
            path: '/now-playing',
            pageBuilder: (context, state) =>
                _slideUp(state, const NowPlayingScreen()),
          ),
        ],
      ),
    ],
  );
});

String _decode(String value) {
  try {
    return decodeName(value);
  } catch (_) {
    return value;
  }
}
