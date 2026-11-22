import 'package:flutter/foundation.dart';

import 'app_db.dart';

/// Local diagnostics. Never log song titles, file paths, accounts or tokens.
abstract final class AppLog {
  static AppDb? _db;

  static void attach(AppDb db) => _db = db;

  static void log(String kind, String message) {
    if (kDebugMode) debugPrint('[$kind] $message');
    _db?.addEvent(kind, message).catchError((Object _) {});
  }

  static void logError(String kind, Object error, StackTrace stackTrace) {
    log(kind, '${error.runtimeType}\n$stackTrace');
  }

  static void installErrorHandlers() {
    final previousFlutterError = FlutterError.onError;
    FlutterError.onError = (details) {
      logError(
        'flutter',
        details.exception,
        details.stack ?? StackTrace.current,
      );
      if (previousFlutterError != null) {
        previousFlutterError(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    final previousPlatformError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      logError('uncaught', error, stackTrace);
      return previousPlatformError?.call(error, stackTrace) ?? false;
    };
  }
}
