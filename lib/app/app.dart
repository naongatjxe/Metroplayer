import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/motion/motion.dart';
import '../core/strings.dart';
import '../core/theme/theme.dart';
import '../features/shared/mini_player.dart';
import 'scan_controller.dart';
import 'providers.dart';
import 'router.dart';

class MetroPlayerApp extends ConsumerStatefulWidget {
  const MetroPlayerApp({super.key});

  @override
  ConsumerState<MetroPlayerApp> createState() => _MetroPlayerAppState();
}

class _MetroPlayerAppState extends ConsumerState<MetroPlayerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scanAutomatically());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scanAutomatically();
  }

  void _scanAutomatically() {
    if (mounted) {
      unawaited(ref.read(scanProvider.notifier).scan(automatic: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    Motion.mode = settings.motionMode;
    return MaterialApp.router(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(settings.accentColor),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarContrastEnforced: false,
          systemStatusBarContrastEnforced: false,
        ),
        child: child!,
      ),
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
