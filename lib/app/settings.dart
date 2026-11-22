import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/tokens.dart';

/// Everything the user can change. Persisted in SharedPreferences.
class AppSettings {
  const AppSettings({
    this.accent = 'blue',
    this.artistCategory = 'artist',
    this.motionMode = 0,
    this.songSort = 'title',
    this.albumSort = 'title',
    this.keepPlaying = true,
    this.showRecent = true,
    this.showFavourites = true,
    this.showMostPlayed = true,
  });

  /// Name of one of [AccentColor.all].
  final String accent;

  /// 'artist' or 'album' (album artist).
  final String artistCategory;

  /// 0 = follow system, 1 = reduce, 2 = full.
  final int motionMode;

  final String songSort;
  final String albumSort;
  final bool keepPlaying;
  final bool showRecent;
  final bool showFavourites;
  final bool showMostPlayed;

  AccentColor get accentColor => AccentColor.all
      .firstWhere((a) => a.name == accent, orElse: () => AccentColor.all.first);

  AppSettings copyWith({
    String? accent,
    String? artistCategory,
    int? motionMode,
    String? songSort,
    String? albumSort,
    bool? keepPlaying,
    bool? showRecent,
    bool? showFavourites,
    bool? showMostPlayed,
  }) {
    return AppSettings(
      accent: accent ?? this.accent,
      artistCategory: artistCategory ?? this.artistCategory,
      motionMode: motionMode ?? this.motionMode,
      songSort: songSort ?? this.songSort,
      albumSort: albumSort ?? this.albumSort,
      keepPlaying: keepPlaying ?? this.keepPlaying,
      showRecent: showRecent ?? this.showRecent,
      showFavourites: showFavourites ?? this.showFavourites,
      showMostPlayed: showMostPlayed ?? this.showMostPlayed,
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
        songSort: p.getString('songSort') ?? 'title',
        albumSort: p.getString('albumSort') ?? 'title',
        keepPlaying: p.getBool('keepPlaying') ?? true,
        showRecent: p.getBool('showRecent') ?? true,
        showFavourites: p.getBool('showFavourites') ?? true,
        showMostPlayed: p.getBool('showMostPlayed') ?? true,
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

  void setSongSort(String value) {
    state = state.copyWith(songSort: value);
    _prefs.setString('songSort', value);
  }

  void setAlbumSort(String value) {
    state = state.copyWith(albumSort: value);
    _prefs.setString('albumSort', value);
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
}
