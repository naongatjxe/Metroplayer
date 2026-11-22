import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';

Future<String?> showAlphaJumpDialog(
  BuildContext context, {
  required Map<String, List<String>> labels,
  required String itemName,
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'jump to letter',
    barrierColor: Colors.black.withValues(alpha: .92),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => _AlphaJumpGrid(
        labels: labels, itemName: itemName, accent: context.accentFill),
    transitionBuilder: (_, animation, __, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween(begin: 1.08, end: 1.0).animate(animation),
        child: child,
      ),
    ),
  );
}

class _AlphaJumpGrid extends StatefulWidget {
  const _AlphaJumpGrid({
    required this.labels,
    required this.itemName,
    required this.accent,
  });

  final Map<String, List<String>> labels;
  final String itemName;
  final Color accent;

  @override
  State<_AlphaJumpGrid> createState() => _AlphaJumpGridState();
}

class _AlphaJumpGridState extends State<_AlphaJumpGrid> {
  String? _held;

  @override
  Widget build(BuildContext context) {
    final letters = [
      '#',
      ...List.generate(26, (index) => String.fromCharCode(97 + index)),
    ];
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: letters.map(_tile).toList(),
                ),
              ),
            ),
          ),
          _previewPanel(),
        ],
      ),
    );
  }

  Widget _tile(String letter) {
    final enabled = widget.labels.containsKey(letter);
    final held = _held == letter;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _held = letter) : null,
      onTapCancel: enabled ? () => setState(() => _held = null) : null,
      onTap: enabled ? () => Navigator.of(context).pop(letter) : null,
      child: AnimatedScale(
        scale: held ? 0.93 : 1,
        duration: const Duration(milliseconds: 90),
        child: Container(
          decoration: BoxDecoration(
            color: enabled ? widget.accent : const Color(0xFF2A2A2A),
          ),
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.fromLTRB(10, 0, 0, 6),
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w300,
              color: enabled ? Colors.white : Colors.white24,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _previewPanel() {
    final letter = _held;
    final names = letter == null ? const <String>[] : widget.labels[letter]!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: letter == null ? 0 : 128,
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(16, 0, 16, letter == null ? 0 : 16),
      padding: letter == null ? EdgeInsets.zero : const EdgeInsets.all(14),
      color: const Color(0xFF1C1C1C),
      child: letter == null
          ? null
          : Row(
              children: [
                Container(
                  width: 72,
                  height: double.infinity,
                  color: widget.accent,
                  alignment: Alignment.center,
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${names.length} ${widget.itemName}'
                        '${names.length == 1 ? '' : 's'}',
                        style: TextStyle(color: widget.accent, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      ...names.take(3).map(
                            (name) => Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                      if (names.length > 3)
                        Text(
                          '+ ${names.length - 3} more',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .5),
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
