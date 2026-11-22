import 'package:material_ui/material_ui.dart';

import '../theme/app_icons.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

/// Standard Metro page: back circle, small label, optional actions, content.
class MetroPage extends StatelessWidget {
  const MetroPage({
    super.key,
    required this.child,
    this.label = '',
    this.header,
    this.headerStyle,
    this.actions = const [],
    this.showBack = true,
  });

  final Widget child;
  final String label;
  final String? header;
  final TextStyle? headerStyle;
  final List<Widget> actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mt.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Mt.pad, 12, Mt.pad, 8),
              child: Row(
                children: [
                  if (showBack) ...[
                    CircleButton(
                      label: 'back',
                      icon: AppIcons.back,
                      size: 44,
                      iconSize: 20,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Mt.topLabel),
                  ),
                  for (final a in actions) ...[const SizedBox(width: 12), a],
                ],
              ),
            ),
            if (header != null) PageHeader(header!, style: headerStyle),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Mt.pad, 4, Mt.pad, 8),
        child: Semantics(
          header: true,
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style ?? Mt.header),
        ),
      );
}
