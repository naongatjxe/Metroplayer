import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_db.dart';
import '../data/app_log.dart';
import '../domain/models.dart';

/// The only owner of the audio player. The UI talks to it through providers.
/// Gapless queue (ConcatenatingAudioSource), persistence, sleep timer, play counts.
class AppAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  AppAudioHandler(this._db, this._prefs, this._artDir) {
    _init();
  }

  final AppDb _db;
  final SharedPreferences _prefs;
  final String _artDir;
  final AudioPlayer _player = AudioPlayer();

  ConcatenatingAudioSource _source =
      ConcatenatingAudioSource(children: <AudioSource>[]);
  List<Track> _tracks = [];
  int? _lastIndex;
  bool _counted = false;
  bool _historyMarked = false;
  Future<void> _nextSkipQueue = Future<void>.value();
  final StreamController<int> _recentHistory =
      StreamController<int>.broadcast();
  int _recentHistoryVersion = 0;

  Timer? _saveTimer;
  Timer? _sleep;
  bool _sleepAtEnd = false;
  DateTime? _sleepEnd;

  /// null = off, Duration.zero = end of current track, otherwise time left.
  final ValueNotifier<Duration?> sleepRemaining =
      ValueNotifier<Duration?>(null);

  int get currentIndex => _player.currentIndex ?? 0;

  // ---- read-only views used by the UI ----
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<int?> get indexStream => _player.currentIndexStream;
  Stream<int?> get queueIndexStream => _player.sequenceStateStream.map((state) {
        if (state == null) return null;
        final order = state.shuffleModeEnabled
            ? state.shuffleIndices
            : List.generate(state.sequence.length, (index) => index);
        final queueIndex = order.indexOf(state.currentIndex);
        return queueIndex < 0 ? null : queueIndex;
      });
  Stream<int> get recentHistoryStream => _recentHistory.stream;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  bool get playing => _player.playing;
  bool get shuffleEnabled => _player.shuffleModeEnabled;
  LoopMode get loopMode => _player.loopMode;
  List<Track> get tracks => List.unmodifiable(_tracks);

  List<int> get _queueOrder {
    final order = _player.effectiveIndices;
    if (_player.shuffleModeEnabled &&
        order != null &&
        order.length == _tracks.length) {
      return order;
    }
    return List.generate(_tracks.length, (index) => index);
  }

  int _sourceIndex(int queueIndex) =>
      queueIndex >= 0 && queueIndex < _queueOrder.length
          ? _queueOrder[queueIndex]
          : -1;

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _player.playbackEventStream
        .map(_transform)
        .listen(playbackState.add, onError: _onPlayerError);
    _player.currentIndexStream.listen(_onIndex);
    _player.durationStream.listen(_onDuration);
    _player.positionStream.listen(_onPosition);
    _player.playingStream.listen((playing) {
      if (playing) {
        unawaited(_markCurrentPlayStarted());
      } else {
        saveQueueNow();
      }
    });
    Timer.periodic(const Duration(seconds: 5), (_) {
      if (_player.playing) saveQueueNow();
    });
  }

  // ---- mapping ----
  AudioSource _src(Track t) => AudioSource.uri(Uri.file(t.path), tag: t.id);

  MediaItem _item(Track t) => MediaItem(
        id: '${t.id}',
        title: t.title,
        artist: t.artist,
        album: t.album,
        duration: t.duration,
        artUri: t.artKey == null
            ? null
            : Uri.file(p.join(_artDir, '${t.artKey}_600.jpg')),
        extras: {'art': t.artKey, 'tid': t.id},
      );

  AudioProcessingState _proc(ProcessingState s) => switch (s) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      };

  AudioServiceRepeatMode _repeat(LoopMode m) => switch (m) {
        LoopMode.off => AudioServiceRepeatMode.none,
        LoopMode.one => AudioServiceRepeatMode.one,
        LoopMode.all => AudioServiceRepeatMode.all,
      };

  AudioServiceShuffleMode get _shuffleMode => _player.shuffleModeEnabled
      ? AudioServiceShuffleMode.all
      : AudioServiceShuffleMode.none;

  PlaybackState _transform(PlaybackEvent e) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _proc(_player.processingState),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: e.currentIndex,
      repeatMode: _repeat(_player.loopMode),
      shuffleMode: _shuffleMode,
    );
  }

  void _pushModes() => playbackState.add(
        playbackState.value.copyWith(
            repeatMode: _repeat(_player.loopMode), shuffleMode: _shuffleMode),
      );

  void _pushQueue() {
    queue.add([for (final i in _queueOrder) _item(_tracks[i])]);
    _scheduleSave();
  }

  // ---- stream handlers ----
  void _onPlayerError(Object e, StackTrace st) {
    AppLog.log('playback', 'player error: ${e.runtimeType}');
    if (_player.hasNext) {
      unawaited(skipToNext());
    }
  }

  void _onIndex(int? i) {
    if (i != null && i >= 0 && i < _tracks.length) {
      mediaItem.add(_item(_tracks[i]));
    }
    if (_sleepAtEnd && _lastIndex != null && i != _lastIndex) {
      _sleepAtEnd = false;
      sleepRemaining.value = null;
      _player.pause();
    }
    _lastIndex = i;
    _counted = false;
    _historyMarked = false;
    if (_player.playing) unawaited(_markCurrentPlayStarted());
    _scheduleSave();
  }

  Future<void> _markCurrentPlayStarted() async {
    if (_historyMarked) return;
    final i = _player.currentIndex;
    if (i == null || i < 0 || i >= _tracks.length) return;
    _historyMarked = true;
    try {
      await _db.markPlayStarted(_tracks[i].id);
      _recentHistory.add(++_recentHistoryVersion);
    } catch (e) {
      _historyMarked = false;
      AppLog.log('playback', 'could not update play history: ${e.runtimeType}');
    }
  }

  void _onDuration(Duration? d) {
    final i = _player.currentIndex;
    if (d == null || i == null || i < 0 || i >= _tracks.length) return;
    mediaItem.add(_item(_tracks[i]).copyWith(duration: d));
  }

  void _onPosition(Duration pos) {
    if (_counted || !_player.playing) return;
    final dur = _player.duration;
    final threshold = dur == null
        ? const Duration(seconds: 30)
        : Duration(milliseconds: math.min(30000, dur.inMilliseconds ~/ 2));
    if (pos >= threshold) {
      _counted = true;
      final i = _player.currentIndex;
      if (i != null && i >= 0 && i < _tracks.length) {
        _db.recordPlay(_tracks[i].id);
      }
    }
  }

  // ---- queue API (used by the UI) ----
  Future<void> playTracks(
    List<Track> list,
    int index, {
    bool? shuffle,
    bool autoplay = true,
    Duration position = Duration.zero,
  }) async {
    if (list.isEmpty) return;
    final start = index.clamp(0, list.length - 1).toInt();
    _tracks = List.of(list);
    _source =
        ConcatenatingAudioSource(children: [for (final t in _tracks) _src(t)]);
    mediaItem.add(_item(_tracks[start]));
    try {
      await _player.setAudioSource(_source,
          initialIndex: start, initialPosition: position);
    } catch (e) {
      AppLog.log('playback', 'could not load the queue: ${e.runtimeType}');
      return;
    }
    if (shuffle != null) {
      await _player.setShuffleModeEnabled(shuffle);
      _pushModes();
    }
    if (shuffle == true || (shuffle == null && _player.shuffleModeEnabled)) {
      await _player.shuffle();
    }
    _pushQueue();
    if (autoplay) unawaited(_player.play());
    _scheduleSave();
  }

  Future<void> playNext(Track t) async {
    if (_tracks.isEmpty) {
      await playTracks([t], 0);
      return;
    }
    final i = math.min(currentIndex + 1, _tracks.length);
    _tracks.insert(i, t);
    await _source.insert(i, _src(t));
    _pushQueue();
  }

  Future<void> addToQueue(Track t) async {
    if (_tracks.isEmpty) {
      await playTracks([t], 0);
      return;
    }
    _tracks.add(t);
    await _source.add(_src(t));
    _pushQueue();
  }

  Future<void> moveQueueItem(int from, int to) async {
    final sourceFrom = _sourceIndex(from);
    final sourceTo = _sourceIndex(to);
    if (sourceFrom < 0 || sourceTo < 0 || sourceFrom == sourceTo) {
      return;
    }
    final t = _tracks.removeAt(sourceFrom);
    _tracks.insert(sourceTo, t);
    await _source.move(sourceFrom, sourceTo);
    _pushQueue();
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    final sourceIndex = _sourceIndex(index);
    if (sourceIndex < 0) return;
    _tracks.removeAt(sourceIndex);
    await _source.removeAt(sourceIndex);
    _pushQueue();
  }

  Future<void> clearQueue() async {
    await _player.stop();
    _tracks = [];
    queue.add(<MediaItem>[]);
    mediaItem.add(null);
    await saveQueueNow();
    try {
      await _source.clear();
    } catch (_) {}
  }

  // ---- transport ----
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await saveQueueNow();
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() {
    final request = _nextSkipQueue.then((_) => _player.seekToNext());
    _nextSkipQueue = request.catchError((Object error, StackTrace stackTrace) {
      AppLog.log(
          'playback', 'could not skip to next track: ${error.runtimeType}');
    });
    return _nextSkipQueue;
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
    } else {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final sourceIndex = _sourceIndex(index);
    if (sourceIndex < 0) return;
    await _player.seek(Duration.zero, index: sourceIndex);
    unawaited(_player.play());
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final on = shuffleMode != AudioServiceShuffleMode.none;
    await _player.setShuffleModeEnabled(on);
    if (on) await _player.shuffle();
    _pushQueue();
    _pushModes();
    _scheduleSave();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await _player.setLoopMode(switch (repeatMode) {
      AudioServiceRepeatMode.none => LoopMode.off,
      AudioServiceRepeatMode.one => LoopMode.one,
      _ => LoopMode.all,
    });
    _pushModes();
    _scheduleSave();
  }

  @override
  Future<void> onTaskRemoved() async {
    if (!(_prefs.getBool('keepPlaying') ?? true)) await stop();
  }

  // ---- sleep timer ----
  void setSleepTimer(Duration? d, {bool endOfTrack = false}) {
    _sleep?.cancel();
    _sleepAtEnd = false;
    _sleepEnd = null;
    _player.setVolume(1);
    if (endOfTrack) {
      _sleepAtEnd = true;
      sleepRemaining.value = Duration.zero;
      return;
    }
    if (d == null) {
      sleepRemaining.value = null;
      return;
    }
    _sleepEnd = DateTime.now().add(d);
    sleepRemaining.value = d;
    _sleep = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = _sleepEnd!.difference(DateTime.now());
      if (left <= Duration.zero) {
        t.cancel();
        _player.pause();
        _player.setVolume(1);
        sleepRemaining.value = null;
        return;
      }
      if (left.inSeconds < 5) _player.setVolume(left.inMilliseconds / 5000);
      sleepRemaining.value = left;
    });
  }

  // ---- persistence ----
  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), saveQueueNow);
  }

  Future<void> saveQueueNow() async {
    try {
      await _db.saveQueue(
        [for (final t in _tracks) t.id],
        _player.currentIndex ?? 0,
        _player.position.inMilliseconds,
        _player.shuffleModeEnabled,
        _player.loopMode.index,
      );
    } catch (_) {}
  }

  /// Restores the saved queue paused at the saved position.
  Future<void> restore() async {
    try {
      final q = await _db.loadQueue();
      if (q == null || q.tracks.isEmpty) return;
      final existing =
          q.tracks.where((t) => File(t.path).existsSync()).toList();
      if (existing.isEmpty) return;
      final curId = q.index >= 0 && q.index < q.tracks.length
          ? q.tracks[q.index].id
          : null;
      var idx = existing.indexWhere((t) => t.id == curId);
      final pos = idx >= 0 ? q.positionMs : 0;
      if (idx < 0) idx = 0;
      await playTracks(
        existing,
        idx,
        shuffle: q.shuffle,
        autoplay: false,
        position: Duration(milliseconds: pos),
      );
      await _player.setLoopMode(LoopMode.values[q.repeat.clamp(0, 2).toInt()]);
      _pushModes();
    } catch (_) {
      AppLog.log('restore', 'queue restore failed');
    }
  }
}
