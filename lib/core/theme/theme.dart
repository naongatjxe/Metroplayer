import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

ThemeData buildTheme(AccentColor a) {
  return ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    fontFamily: Mt.font,
    scaffoldBackgroundColor: Mt.bg,
    canvasColor: Mt.bg,
    dividerColor: Mt.outline,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    colorScheme: ColorScheme.dark(
      primary: a.text,
      secondary: a.fill,
      surface: Mt.bg,
      onSurface: Mt.text,
      outline: Mt.outline,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: a.text,
      selectionHandleColor: a.text,
    ),
  );
}
