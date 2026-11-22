import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/widgets/controls.dart';

Future<void> showSleepTimerSheet(BuildContext context, WidgetRef ref) async {
  final handler = ref.read(audioHandlerProvider);
  final active = handler.sleepRemaining.value;
  final choice = await showMetroSheet<String>(
    context,
    builder: (c) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionLabel('sleep timer'),
        if (active != null)
          SheetItem(label: 'off', onTap: () => Navigator.pop(c, 'off')),
        SheetItem(
            label: 'end of current track',
            onTap: () => Navigator.pop(c, 'end')),
        for (final m in const [15, 30, 45, 60])
          SheetItem(label: '$m minutes', onTap: () => Navigator.pop(c, '$m')),
      ],
    ),
  );
  if (choice == null) return;
  switch (choice) {
    case 'off':
      handler.setSleepTimer(null);
    case 'end':
      handler.setSleepTimer(Duration.zero, endOfTrack: true);
    default:
      final minutes = int.tryParse(choice);
      if (minutes != null) handler.setSleepTimer(Duration(minutes: minutes));
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(choice == 'off' ? 'sleep timer off' : 'sleep timer set')),
    );
  }
}
