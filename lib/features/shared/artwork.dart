import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;

import '../../app/providers.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';

/// Album art from the cache folder, with the bundled placeholder on failure.
class Artwork extends ConsumerWidget {
  const Artwork({
    super.key,
    this.artKey,
    this.size,
    this.width,
    this.height,
    this.placeholder = AppIcons.albumPlaceholder,
  });

  final String? artKey;
  final double? size;
  final double? width;
  final double? height;
  final String placeholder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dir = ref.watch(artDirProvider);
    final w = width ?? size;
    final h = height ?? size;
    return SizedBox(
      width: w,
      height: h,
      child: LayoutBuilder(
        builder: (context, box) {
          final pw = box.maxWidth.isFinite ? box.maxWidth : (w ?? 64);
          final ph = box.maxHeight.isFinite ? box.maxHeight : (h ?? pw);
          Widget fallback() => SvgPicture.asset(
                placeholder,
                width: pw,
                height: ph,
                fit: BoxFit.cover,
              );
          final key = artKey;
          if (key == null || key.isEmpty) return fallback();
          final file = File(p.join(dir, '${key}_600.jpg'));
          final dpr = MediaQuery.devicePixelRatioOf(context);
          return Image.file(
            file,
            width: pw,
            height: ph,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            cacheWidth: (pw * dpr).round().clamp(64, 1400),
            errorBuilder: (_, __, ___) => fallback(),
          );
        },
      ),
    );
  }
}

/// Square artwork with a thin outline, used for album cards.
class ArtworkCard extends StatelessWidget {
  const ArtworkCard(
      {super.key, this.artKey, this.placeholder = AppIcons.albumPlaceholder});
  final String? artKey;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration:
          BoxDecoration(border: Border.all(color: Mt.outline, width: 1)),
      child: AspectRatio(
        aspectRatio: 1,
        child: Artwork(artKey: artKey, placeholder: placeholder),
      ),
    );
  }
}
