import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Paths of the bundled Metro icons (assets/icons/*.svg). Icons are white;
/// tint them with [MetroIcon.color].
abstract final class AppIcons {
  static const _base = 'assets/icons';
  static const back = '$_base/back.svg';
  static const search = '$_base/search.svg';
  static const queue = '$_base/queue.svg';
  static const add = '$_base/add.svg';
  static const close = '$_base/close.svg';
  static const check = '$_base/check.svg';
  static const play = '$_base/play.svg';
  static const pause = '$_base/pause.svg';
  static const previous = '$_base/previous.svg';
  static const next = '$_base/next.svg';
  static const shuffle = '$_base/shuffle.svg';
  static const repeat = '$_base/repeat.svg';
  static const repeatOne = '$_base/repeat_one.svg';
  static const heart = '$_base/heart.svg';
  static const heartFilled = '$_base/heart_filled.svg';
  static const listView = '$_base/list_view.svg';
  static const gridView = '$_base/grid_view.svg';
  static const chevronDown = '$_base/chevron_down.svg';
  static const equalizer = '$_base/equalizer.svg';
  static const more = '$_base/more.svg';
  static const sleepTimer = '$_base/sleep_timer.svg';
  static const timerOff = '$_base/timer_off.svg';
  static const lyrics = '$_base/lyrics.svg';
  static const folder = '$_base/folder.svg';
  static const refresh = '$_base/refresh.svg';
  static const settings = '$_base/settings.svg';
  static const musicNote = '$_base/music_note.svg';
  static const dragHandle = '$_base/drag_handle.svg';
  static const delete = '$_base/delete.svg';
  static const addToPlaylist = '$_base/add_to_playlist.svg';
  static const volume = '$_base/volume.svg';

  static const albumPlaceholder = 'assets/images/album_placeholder.svg';
  static const artistPlaceholder = 'assets/images/artist_placeholder.svg';
  static const emptyLibrary = 'assets/images/empty_library.svg';
}

/// Tintable icon. Pass [semanticLabel] for icon-only controls.
class MetroIcon extends StatelessWidget {
  const MetroIcon(
    this.asset, {
    super.key,
    this.size = 24,
    this.color = Colors.white,
    this.semanticLabel,
  });

  final String asset;
  final double size;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      semanticsLabel: semanticLabel,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
