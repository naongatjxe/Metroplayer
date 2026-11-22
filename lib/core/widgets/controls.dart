import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_icons.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(Mt.pad, 20, Mt.pad, 8),
  });
  final String text;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: padding, child: Text(text, style: Mt.label));
}

Future<T?> showMetroSheet<T>(BuildContext context,
    {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Mt.surface,
    shape: const RoundedRectangleBorder(),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (c) =>
        SafeArea(top: false, child: SingleChildScrollView(child: builder(c))),
  );
}

class SheetItem extends StatelessWidget {
  const SheetItem(
      {super.key,
      required this.label,
      required this.onTap,
      this.selected = false});
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: label,
      onTap: onTap,
      tilt: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: Mt.pad, vertical: 14),
        child: Text(
          label,
          style: Mt.itemTitle.copyWith(
              fontSize: 24, color: selected ? context.accent : Mt.text),
        ),
      ),
    );
  }
}

class MetroDropdown<T> extends StatelessWidget {
  const MetroDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.label = 'sort',
  });
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: '$label: ${options[value] ?? ''}',
      tilt: false,
      onTap: () => showMetroSheet<void>(
        context,
        builder: (c) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in options.entries)
              SheetItem(
                label: e.value,
                selected: e.key == value,
                onTap: () {
                  Navigator.pop(c);
                  onChanged(e.key);
                },
              ),
          ],
        ),
      ),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Mt.surfaceAlt,
          border: Border.all(color: Mt.outline, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                options[value] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Mt.body.copyWith(color: context.accent),
              ),
            ),
            const MetroIcon(AppIcons.chevronDown, size: 18, color: Mt.dim),
          ],
        ),
      ),
    );
  }
}

class MetroRadio extends StatelessWidget {
  const MetroRadio(
      {super.key,
      required this.selected,
      required this.label,
      required this.onTap});
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.accent;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: Pressable(
        label: label,
        onTap: onTap,
        tilt: false,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? null : const Color(0xFF333333),
                  border: Border.all(
                      color: selected ? accent : const Color(0xFF666666),
                      width: 2),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: accent),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      Mt.itemTitle.copyWith(color: selected ? accent : Mt.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MetroInput extends StatelessWidget {
  const MetroInput({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: c, width: 2));
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      cursorColor: context.accent,
      style: Mt.item.copyWith(fontSize: 22),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Mt.item.copyWith(fontSize: 22, color: Mt.faint),
        filled: true,
        fillColor: Mt.surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: border(Mt.outline),
        focusedBorder: border(context.accent),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(
      {super.key, required this.message, this.actionLabel, this.onAction});
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Mt.pad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(AppIcons.emptyLibrary, width: 140, height: 140),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: Mt.itemTitle.copyWith(fontSize: 24, color: Mt.dim)),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              Pressable(
                label: actionLabel,
                onTap: onAction,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Text(actionLabel!,
                      style: Mt.itemTitle
                          .copyWith(fontSize: 24, color: context.accent)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton(this.label, this.onTap, {this.color});
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => Pressable(
        label: label,
        onTap: onTap,
        tilt: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child:
              Text(label, style: Mt.rowTitle.copyWith(color: color ?? Mt.text)),
        ),
      );
}

Future<String?> showTextDialog(
  BuildContext context, {
  required String title,
  String initial = '',
  String hint = '',
  String ok = 'ok',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) =>
        _TextDialog(title: title, initial: initial, hint: hint, ok: ok),
  );
}

class _TextDialog extends StatefulWidget {
  const _TextDialog(
      {required this.title,
      required this.initial,
      required this.hint,
      required this.ok});
  final String title;
  final String initial;
  final String hint;
  final String ok;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Mt.surfaceAlt,
      shape: const RoundedRectangleBorder(),
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Mt.itemTitle.copyWith(fontSize: 26)),
            const SizedBox(height: 16),
            MetroInput(
              controller: _c,
              hint: widget.hint,
              autofocus: true,
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _DialogButton('cancel', () => Navigator.pop(context)),
                const SizedBox(width: 20),
                _DialogButton(widget.ok, () => Navigator.pop(context, _c.text),
                    color: context.accent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showConfirm(BuildContext context, String message,
    {String ok = 'delete'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => Dialog(
      backgroundColor: Mt.surfaceAlt,
      shape: const RoundedRectangleBorder(),
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: Mt.itemTitle.copyWith(fontSize: 24)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _DialogButton('cancel', () => Navigator.pop(c, false)),
                const SizedBox(width: 20),
                _DialogButton(ok, () => Navigator.pop(c, true),
                    color: c.accent),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return r ?? false;
}
