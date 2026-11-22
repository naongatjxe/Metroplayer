import 'package:material_ui/material_ui.dart';

/// Metro design tokens. Colours, sizes and type live here only.
abstract final class Mt {
  static const bg = Color(0xFF000000);
  static const surface = Color(0xFF0A0A0A);
  static const surfaceAlt = Color(0xFF111111);
  static const outline = Color(0xFF444444);
  static const text = Color(0xFFFFFFFF);
  static const dim = Color(0xFF9A9A9A);
  static const faint = Color(0xFF555555);
  static const font = 'NotoSerif';
  static const sans = 'OpenSans';
  static const pad = 24.0;

  static const appTitle = TextStyle(
      fontFamily: font,
      fontSize: 46,
      letterSpacing: -1.5,
      height: 1.0,
      color: text);
  static const header = TextStyle(
      fontFamily: font,
      fontSize: 52,
      letterSpacing: -1,
      height: 1.1,
      color: text);
  static const quickTitle = TextStyle(
      fontFamily: sans,
      fontSize: 52,
      fontWeight: FontWeight.w300,
      letterSpacing: -1,
      height: 1.0,
      color: text);
  static const pivotSmall =
      TextStyle(fontFamily: font, fontSize: 22, height: 1.2, color: text);
  static const item =
      TextStyle(fontFamily: font, fontSize: 32, height: 1.2, color: text);
  static const itemTitle =
      TextStyle(fontFamily: font, fontSize: 30, height: 1.2, color: text);
  static const topLabel =
      TextStyle(fontFamily: font, fontSize: 17, letterSpacing: 1, color: dim);
  static const label =
      TextStyle(fontFamily: font, fontSize: 15, letterSpacing: 3, color: dim);
  static const subtitle =
      TextStyle(fontFamily: font, fontSize: 16, height: 1.4, color: dim);
  static const body = TextStyle(fontFamily: font, fontSize: 17, color: text);
  static const rowTitle =
      TextStyle(fontFamily: font, fontSize: 18, color: text);
  static const rowSub = TextStyle(fontFamily: font, fontSize: 14, color: dim);
  static const small = TextStyle(fontFamily: font, fontSize: 13, color: dim);
}

/// [fill] carries white text (>= 4.5:1). [text] is the lighter tint for text and
/// thin lines on black (>= 4.5:1).
@immutable
class AccentColor {
  const AccentColor(this.name, this.fill, this.text);
  final String name;
  final Color fill;
  final Color text;

  static const all = <AccentColor>[
    AccentColor('blue', Color(0xFF1B6EC2), Color(0xFF2A93E0)),
    AccentColor('orange', Color(0xFFC13F00), Color(0xFFE8662A)),
    AccentColor('magenta', Color(0xFFA8186F), Color(0xFFE0509C)),
    AccentColor('green', Color(0xFF1E7B3A), Color(0xFF3DBE63)),
  ];
}

double contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

extension AccentX on BuildContext {
  /// Accent tint for text, icons and thin lines.
  Color get accent => Theme.of(this).colorScheme.primary;

  /// Accent fill for solid blocks that carry white text.
  Color get accentFill => Theme.of(this).colorScheme.secondary;
}
