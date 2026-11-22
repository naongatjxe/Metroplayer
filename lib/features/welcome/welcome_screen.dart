import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/scan_controller.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/metro_page.dart';
import '../../core/widgets/pressable.dart';
import '../shared/excluded_folders.dart';

const welcomeShownPreferenceKey = 'welcomeShown';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(prefsProvider).setBool(welcomeShownPreferenceKey, true);
  }

  @override
  Widget build(BuildContext context) {
    return MetroPage(
      label: 'welcome',
      child: WelcomeView(onContinue: () => context.go('/')),
    );
  }
}

/// Empty-library onboarding. Also embedded on the home screen.
class WelcomeView extends ConsumerWidget {
  const WelcomeView({super.key, this.onContinue});

  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(scanProvider);
    final controller = ref.read(scanProvider.notifier);
    final trackCount = ref.watch(trackCountProvider).valueOrNull ?? 0;
    final settings = ref.watch(settingsProvider);

    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Mt.pad, 24, Mt.pad, 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight - 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const MetroIcon(AppIcons.musicNote, size: 56, color: Mt.dim),
              const SizedBox(height: 20),
              Text('your music,\noffline.',
                  style: Mt.header.copyWith(fontSize: 46)),
              const SizedBox(height: 14),
              const Text(
                'Metro Player plays the audio files on this device. '
                'Point it at a folder and it will read the tags and cover art.',
                style: Mt.subtitle,
              ),
              const SizedBox(height: 20),
              Text(
                'accent color  ·  ${settings.accent}',
                style: Mt.small.copyWith(color: context.accent),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: [
                  for (final accent in AccentColor.all)
                    Pressable(
                      label: '${accent.name} accent',
                      tilt: false,
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .setAccent(accent.name),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accent.fill,
                          border: Border.all(
                            color: settings.accent == accent.name
                                ? Mt.text
                                : Mt.outline,
                            width: settings.accent == accent.name ? 2 : 1,
                          ),
                        ),
                        child: settings.accent == accent.name
                            ? const Center(
                                child: MetroIcon(
                                  AppIcons.check,
                                  size: 20,
                                  color: Mt.text,
                                ),
                              )
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const ExcludedFoldersSection(),
              const SizedBox(height: 28),
              if (scan.scanning) ...[
                LinearProgressIndicator(
                  value: scan.total > 0 ? scan.done / scan.total : null,
                  minHeight: 4,
                  backgroundColor: Mt.outline,
                  color: context.accent,
                ),
                const SizedBox(height: 10),
                Text(
                  scan.total > 0
                      ? 'scanning ${scan.done} of ${scan.total}'
                      : 'looking through your folders…',
                  style: Mt.subtitle,
                ),
                const SizedBox(height: 20),
              ] else ...[
                _BigButton(
                  label: '+ music folder',
                  filled: true,
                  onTap: controller.addFolder,
                ),
                const SizedBox(height: 12),
                _BigButton(
                  label: 'look for music',
                  onTap: controller.scan,
                ),
              ],
              if (scan.message != null) ...[
                const SizedBox(height: 16),
                Text(scan.message!,
                    style: Mt.body.copyWith(color: context.accent)),
              ],
              if (onContinue != null && trackCount > 0) ...[
                const SizedBox(height: 12),
                _BigButton(
                  label: 'start listening',
                  filled: true,
                  onTap: onContinue,
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'android asks for audio access the first time. '
                'no network, no account, no ads.',
                style: Mt.small,
              ),
              const SizedBox(height: 12),
              Pressable(
                label: 'settings',
                tilt: false,
                onTap: () => context.push('/settings'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('settings',
                      style: Mt.rowTitle.copyWith(color: context.accent)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({required this.label, this.onTap, this.filled = false});
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: label,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: filled ? context.accentFill : Mt.surfaceAlt,
          border: Border.all(
              color: filled ? context.accentFill : Mt.outline, width: 2),
        ),
        child: Text(label, style: Mt.itemTitle.copyWith(fontSize: 24)),
      ),
    );
  }
}
