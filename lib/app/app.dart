import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/motion/motion.dart';
import '../core/strings.dart';
import '../core/theme/theme.dart';
import '../features/shared/mini_player.dart';
import 'providers.dart';
import 'router.dart';

class MetroPlayerApp extends ConsumerWidget {
  const MetroPlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    Motion.mode = settings.motionMode;
    return MaterialApp.router(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(settings.accentColor),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

/// Persistent mini player below every page. The full player hides it.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showMini = path != '/now-playing' && path != '/welcome' && !keyboard;
    return Column(
      children: [
        Expanded(child: child),
        if (showMini) const MiniPlayer(),
      ],
    );
  }
}
