import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';

/// Right-edge fast scroller. Drag to jump between letters.
class AlphaScroller extends StatefulWidget {
  const AlphaScroller(
      {super.key,
      required this.letters,
      required this.onLetter,
      this.onActive});
  final List<String> letters;
  final ValueChanged<String> onLetter;
  final ValueChanged<String?>? onActive;

  @override
  State<AlphaScroller> createState() => _AlphaScrollerState();
}

class _AlphaScrollerState extends State<AlphaScroller> {
  String? _last;

  void _hit(double dy, double h) {
    if (widget.letters.isEmpty || h <= 0) return;
    final i = (dy / h * widget.letters.length)
        .floor()
        .clamp(0, widget.letters.length - 1)
        .toInt();
    final l = widget.letters[i];
    if (l != _last) {
      _last = l;
      widget.onLetter(l);
      widget.onActive?.call(l);
    }
  }

  void _end() {
    _last = null;
    widget.onActive?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, box) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: (d) => _hit(d.localPosition.dy, box.maxHeight),
          onVerticalDragUpdate: (d) => _hit(d.localPosition.dy, box.maxHeight),
          onVerticalDragEnd: (_) => _end(),
          onVerticalDragCancel: _end,
          onTapDown: (d) => _hit(d.localPosition.dy, box.maxHeight),
          onTapUp: (_) => _end(),
          onTapCancel: _end,
          child: Container(
            width: 28,
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                children: [
                  for (final l in widget.letters)
                    SizedBox(
                      height: 16,
                      child: Text(l, style: Mt.small.copyWith(fontSize: 11)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
