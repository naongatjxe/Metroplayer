import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/app_db.dart';
import '../data/app_log.dart';
import '../data/scan_worker.dart';
import 'providers.dart';

class ScanState {
  const ScanState({
    this.scanning = false,
    this.total = 0,
    this.done = 0,
    this.tracks = 0,
    this.message,
    this.lastScanMs,
  });

  final bool scanning;
  final int total;
  final int done;
  final int tracks;
  final String? message;
  final int? lastScanMs;

  ScanState copyWith({
    bool? scanning,
    int? total,
    int? done,
    int? tracks,
    String? message,
    bool clearMessage = false,
    int? lastScanMs,
  }) {
    return ScanState(
      scanning: scanning ?? this.scanning,
      total: total ?? this.total,
      done: done ?? this.done,
      tracks: tracks ?? this.tracks,
      message: clearMessage ? null : (message ?? this.message),
      lastScanMs: lastScanMs ?? this.lastScanMs,
    );
  }
}

class ScanController extends StateNotifier<ScanState> {
  ScanController(this._ref) : super(const ScanState());

  final Ref _ref;

  Future<bool> _ensurePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      var s = await Permission.audio.status;
      if (s.isGranted) return true;
      s = await Permission.audio.request();
      if (s.isGranted) return true;
    } catch (_) {
      // Older Android versions do not know READ_MEDIA_AUDIO.
    }
    try {
      var s = await Permission.storage.status;
      if (s.isGranted) return true;
      s = await Permission.storage.request();
      return s.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> _roots(AppDb db) async {
    final roots = await db.sources();
    if (roots.isNotEmpty) return roots;
    if (!Platform.isAndroid) return roots;
    for (final c in const [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/sdcard/Music',
      '/sdcard/Download',
    ]) {
      if (Directory(c).existsSync()) {
        await db.addSource(c);
        roots.add(c);
        // /sdcard is a symlink to the same place as /storage/emulated/0.
        if (c.startsWith('/storage/emulated/0')) break;
      }
    }
    return roots;
  }

  Future<void> addFolder() async {
    state = state.copyWith(clearMessage: true);
    try {
      final path = await FilePicker.platform
          .getDirectoryPath(dialogTitle: 'choose a music folder');
      if (path == null) return;
      if (!Directory(path).existsSync()) {
        state = state.copyWith(message: 'that folder cannot be read');
        return;
      }
      await _ref.read(dbProvider).addSource(path);
      await scan();
    } catch (_) {
      state = state.copyWith(message: 'that folder cannot be read');
    }
  }

  Future<void> removeSource(String path) async {
    final db = _ref.read(dbProvider);
    await db.removeSource(path);
    await db.deleteUnder(path);
    bumpLibrary(_ref);
    state = state.copyWith(clearMessage: true);
  }

  Future<void> scan() async {
    if (state.scanning) return;
    final db = _ref.read(dbProvider);
    state = state.copyWith(clearMessage: true);

    final roots = await _roots(db);
    if (roots.isEmpty) {
      state = state.copyWith(message: 'add a music folder first');
      return;
    }
    if (!await _ensurePermission()) {
      state = state.copyWith(
          message: 'storage permission is needed to read your music');
      return;
    }

    final known = await db.knownTracks();
    final ids = <String, int>{for (final e in known.entries) e.key: e.value.$1};
    final artDir = _ref.read(artDirProvider);
    state = const ScanState(scanning: true);

    final rp = ReceivePort();
    final done = Completer<void>();
    final seen = <String>{};
    Isolate? isolate;

    Future<void> handle(Map<Object?, Object?> m) async {
      switch (m['t']) {
        case 'total':
          state = state.copyWith(total: (m['n'] as num?)?.toInt() ?? 0);
        case 'batch':
          final raw = (m['rows'] as List?) ?? const [];
          final rows = [
            for (final r in raw) Map<String, Object?>.from(r as Map)
          ];
          await db.upsertBatch(rows, ids);
          state = state.copyWith(done: state.done + rows.length);
        case 'log':
          AppLog.log('scan', (m['msg'] as String?) ?? 'scan message');
        case 'done':
          final raw = (m['seen'] as List?) ?? const [];
          seen.addAll(raw.whereType<String>());
          await db.deleteMissing(seen, roots);
          bumpLibrary(_ref);
          final count = await db.trackCount();
          state = state.copyWith(
            scanning: false,
            tracks: count,
            lastScanMs: DateTime.now().millisecondsSinceEpoch,
            message: count == 0 ? 'no music found' : null,
            clearMessage: count != 0,
          );
          if (!done.isCompleted) done.complete();
      }
    }

    var chain = Future<void>.value();
    rp.listen((message) {
      if (message is! Map) {
        // Isolate.spawn sends an error list, then null on exit.
        if (message is List) {
          AppLog.log('scan', 'the scan worker failed');
          if (!done.isCompleted) {
            state = state.copyWith(
                scanning: false, message: 'the scan stopped early');
            done.complete();
          }
        }
        return;
      }
      chain = chain.then((_) async {
        try {
          await handle(message as Map<Object?, Object?>);
        } catch (_) {
          AppLog.log('scan', 'a batch could not be saved');
        }
      });
    });

    try {
      isolate = await Isolate.spawn<ScanRequest>(
        scanWorker,
        ScanRequest(rp.sendPort, roots,
            {for (final e in known.entries) e.key: e.value.$2}, artDir),
        onError: rp.sendPort,
        onExit: rp.sendPort,
      );
      await done.future.timeout(const Duration(minutes: 10));
      await chain;
    } catch (_) {
      AppLog.log('scan', 'the scan stopped early');
      state =
          state.copyWith(scanning: false, message: 'the scan stopped early');
    } finally {
      isolate?.kill(priority: Isolate.immediate);
      rp.close();
    }
  }
}

final scanProvider = StateNotifierProvider<ScanController, ScanState>(
    (ref) => ScanController(ref));
