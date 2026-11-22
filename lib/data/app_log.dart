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
}
