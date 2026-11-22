import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/tokens.dart';

/// Everything the user can change. Persisted in SharedPreferences.
class AppSettings {
  const AppSettings({
    this.accent = 'blue',
    this.artistCategory = 'artist',
    this.motionMode = 0,
    this.keepPlaying = true,
    this.showRecent = true,
    this.showFavourites = true,
    this.showMostPlayed = true,
    this.excludedFolders = const [],
  });

  /// Name of one of [AccentColor.all].
  final String accent;

  /// 'artist' or 'album' (album artist).
  final String artistCategory;

  /// 0 = follow system, 1 = reduce, 2 = full.
  final int motionMode;

  final bool keepPlaying;
  final bool showRecent;
  final bool showFavourites;
  final bool showMostPlayed;
  final List<String> excludedFolders;

  AccentColor get accentColor => AccentColor.all
      .firstWhere((a) => a.name == accent, orElse: () => AccentColor.all.first);

  AppSettings copyWith({
    String? accent,
    String? artistCategory,
    int? motionMode,
    bool? keepPlaying,
    bool? showRecent,
    bool? showFavourites,
    bool? showMostPlayed,
    List<String>? excludedFolders,
  }) {
    return AppSettings(
      accent: accent ?? this.accent,
      artistCategory: artistCategory ?? this.artistCategory,
      motionMode: motionMode ?? this.motionMode,
      keepPlaying: keepPlaying ?? this.keepPlaying,
      showRecent: showRecent ?? this.showRecent,
      showFavourites: showFavourites ?? this.showFavourites,
      showMostPlayed: showMostPlayed ?? this.showMostPlayed,
      excludedFolders: excludedFolders ?? this.excludedFolders,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static AppSettings _read(SharedPreferences p) => AppSettings(
        accent: p.getString('accent') ?? 'blue',
        artistCategory: p.getString('artistCategory') ?? 'artist',
        motionMode: p.getInt('motionMode') ?? 0,
        keepPlaying: p.getBool('keepPlaying') ?? true,
        showRecent: p.getBool('showRecent') ?? true,
        showFavourites: p.getBool('showFavourites') ?? true,
        showMostPlayed: p.getBool('showMostPlayed') ?? true,
        excludedFolders: p.getStringList('excludedFolders') ?? const [],
      );

  void setAccent(String value) {
    state = state.copyWith(accent: value);
    _prefs.setString('accent', value);
  }

  void setArtistCategory(String value) {
    state = state.copyWith(artistCategory: value);
    _prefs.setString('artistCategory', value);
  }

  void setMotionMode(int value) {
    state = state.copyWith(motionMode: value);
    _prefs.setInt('motionMode', value);
  }

  void setKeepPlaying(bool value) {
    state = state.copyWith(keepPlaying: value);
    _prefs.setBool('keepPlaying', value);
  }

  void setShowRecent(bool value) {
    state = state.copyWith(showRecent: value);
    _prefs.setBool('showRecent', value);
  }

  void setShowFavourites(bool value) {
    state = state.copyWith(showFavourites: value);
    _prefs.setBool('showFavourites', value);
  }

  void setShowMostPlayed(bool value) {
    state = state.copyWith(showMostPlayed: value);
    _prefs.setBool('showMostPlayed', value);
  }

  void setExcludedFolders(List<String> value) {
    final folders = List<String>.unmodifiable(value);
    state = state.copyWith(excludedFolders: folders);
    _prefs.setStringList('excludedFolders', folders);
  }
}
