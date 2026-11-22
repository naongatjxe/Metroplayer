import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/scan_controller.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pressable.dart';

class ExcludedFoldersSection extends ConsumerWidget {
  const ExcludedFoldersSection({super.key, this.showHeading = true});

  final bool showHeading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(settingsProvider).excludedFolders;
    final scanning = ref.watch(scanProvider).scanning;
    final controller = ref.read(scanProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeading) ...[
          Text(
            'folders skipped by scans',
            style: Mt.small.copyWith(color: context.accent),
          ),
        ],
        const SizedBox(height: 4),
        const Text(
          'Tracks here and in subfolders are removed from the library; '
          'your files are not deleted.',
          style: Mt.small,
        ),
        if (folders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('no folders excluded', style: Mt.rowSub),
          ),
        for (final folder in folders)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    folder,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Mt.rowSub.copyWith(color: Mt.text),
                  ),
                ),
                Pressable(
                  label: 'remove excluded folder',
                  tilt: false,
                  onTap: scanning
                      ? null
                      : () => controller.removeExcludedFolder(folder),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: MetroIcon(AppIcons.close, size: 18, color: Mt.dim),
                  ),
                ),
              ],
            ),
          ),
        Pressable(
          label: 'exclude a folder from scans',
          tilt: false,
          onTap: scanning ? null : controller.addExcludedFolder,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                MetroIcon(AppIcons.folder, size: 20, color: context.accent),
                const SizedBox(width: 8),
                Text(
                  'exclude a folder',
                  style: Mt.rowTitle.copyWith(color: context.accent),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
