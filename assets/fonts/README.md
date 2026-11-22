# Fonts to add (I could not download them for you)

Both fonts are free under the SIL Open Font License 1.1 and can be bundled in the app.

Required files in this folder (exact names, as used in pubspec_snippet.yaml):

| File | Family |
|------|--------|
| NotoSerif-Regular.ttf | Noto Serif |
| NotoSerif-Italic.ttf | Noto Serif |
| NotoSerif-SemiBold.ttf | Noto Serif |
| OpenSans-Light.ttf (optional) | Open Sans |
| OpenSans-Regular.ttf (optional) | Open Sans |
| OpenSans-SemiBold.ttf (optional) | Open Sans |

Where to get them:
- Noto Serif (Google Fonts): https://fonts.google.com/noto/specimen/Noto+Serif
- Noto Serif source files: https://github.com/google/fonts/tree/main/ofl/notoserif
- Noto Serif (Fontsource, all weights as separate files): https://fontsource.org/fonts/noto-serif
- Noto usage and download help: https://fonts.google.com/noto/use
- Open Sans (Google Fonts): https://fonts.google.com/specimen/Open+Sans
- Open Sans (Fontsource): https://fontsource.org/fonts/open-sans

Notes:
- The Google download is often a single variable font, for example `NotoSerif-VariableFont_wdth,wght.ttf`, with the static weights in a `static/` folder inside the zip. Use the static files and rename them to the names above if needed.
- Do not use the google_fonts package at runtime. This app is offline, so fonts must be bundled.
- Keep each font's OFL.txt next to it (for example `assets/fonts/OFL-NotoSerif.txt`) and list the fonts on the licences screen.
