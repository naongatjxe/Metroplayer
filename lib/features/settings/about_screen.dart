import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/strings.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/metro_page.dart';
import '../../core/widgets/pressable.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  static final _githubUri = Uri.parse('https://github.com/naongatjxe');

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return MetroPage(
      label: 'your player',
      header: 'about',
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Mt.pad, 12, Mt.pad, 4),
            child: Text(
              S.appName,
              style: Mt.header.copyWith(color: context.accent),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Mt.pad),
            child: Text(
              'An offline music player with a Zune-inspired Metro design. '
              'Your music stays on your device.',
              style: Mt.subtitle,
            ),
          ),
          const SectionLabel('app'),
          FutureBuilder<PackageInfo>(
            future: _packageInfo,
            builder: (context, snapshot) {
              final version = snapshot.hasError
                  ? 'unavailable: ${snapshot.error}'
                  : snapshot.hasData
                      ? '${snapshot.data!.version} '
                          '(${snapshot.data!.buildNumber})'
                      : 'loading…';
              return _AboutRow(label: 'version', value: version);
            },
          ),
          const _AboutRow(label: 'maintainer', value: 'Naonga Gondwe'),
          Pressable(
            label: 'open GitHub profile',
            tilt: false,
            onTap: _openGithub,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Mt.pad,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'GitHub',
                      style: Mt.rowTitle.copyWith(color: context.accent),
                    ),
                  ),
                  Text(
                    'github.com/naongatjxe',
                    style: Mt.subtitle.copyWith(color: context.accent),
                  ),
                ],
              ),
            ),
          ),
          const SectionLabel('more'),
          Pressable(
            label: 'open licences',
            tilt: false,
            onTap: () => showLicensePage(
              context: context,
              applicationName: S.appName,
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: Mt.pad, vertical: 14),
              child: Text('open-source licences', style: Mt.rowTitle),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openGithub() async {
    final opened = await launchUrl(
      AboutScreen._githubUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the GitHub profile.')),
      );
    }
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Mt.pad, vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Mt.rowTitle)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Mt.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}
