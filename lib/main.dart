import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'audio/audio_handler.dart';
import 'data/app_db.dart';
import 'data/app_log.dart';

void main() {
  runZonedGuarded<Future<void>>(_initializeApp, (error, stackTrace) {
    AppLog.logError('zone', error, stackTrace);
  });
}

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final db = await AppDb.open();
  AppLog.attach(db);
  AppLog.installErrorHandlers();
  final prefs = await SharedPreferences.getInstance();

  final support = await getApplicationSupportDirectory();
  final artDir = p.join(support.path, 'art');
  await Directory(artDir).create(recursive: true);

  final handler = await AudioService.init(
    builder: () => AppAudioHandler(db, prefs, artDir),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.commandline.metroplayer.playback',
      androidNotificationChannelName: 'Playback',
      androidNotificationChannelDescription:
          'Playback controls for Metro Player',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
        prefsProvider.overrideWithValue(prefs),
        artDirProvider.overrideWithValue(artDir),
        audioHandlerProvider.overrideWithValue(handler),
      ],
      child: const MetroPlayerApp(),
    ),
  );

  unawaited(handler.restore());
  if (Platform.isAndroid) {
    unawaited(_askForNotifications());
  }
}

Future<void> _askForNotifications() async {
  try {
    final status = await Permission.notification.status;
    if (status.isDenied) await Permission.notification.request();
  } catch (e) {
    if (kDebugMode) debugPrint('notification permission unavailable: $e');
  }
}
