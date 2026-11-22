import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';
import '../utils.dart';

/// Flat progress slider: thin track, accent fill, small rectangular thumb that
/// grows while dragging. Values are milliseconds.
class MetroSlider extends StatefulWidget {
  const MetroSlider(
      {super.key,
      required this.value,
      required this.max,
      required this.onSeek});
  final double value;
  final double max;
  final ValueChanged<double> onSeek;

  @override
  State<MetroSlider> createState() => _MetroSliderState();
}

class _MetroSliderState extends State<MetroSlider> {
  double? _drag;

  double _at(double dx, double w) =>
      (dx / w).clamp(0.0, 1.0).toDouble() * widget.max;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final v = (_drag ?? widget.value)
            .clamp(0.0, widget.max <= 0 ? 1.0 : widget.max)
            .toDouble();
        final frac = widget.max <= 0 ? 0.0 : v / widget.max;
        return Semantics(
          slider: true,
          label: 'seek',
          value:
              '${fmtDur(Duration(milliseconds: v.round()))} of ${fmtDur(Duration(milliseconds: widget.max.round()))}',
          onIncrease: () =>
              widget.onSeek((v + 10000).clamp(0.0, widget.max).toDouble()),
          onDecrease: () =>
              widget.onSeek((v - 10000).clamp(0.0, widget.max).toDouble()),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) =>
                setState(() => _drag = _at(d.localPosition.dx, w)),
            onHorizontalDragUpdate: (d) =>
                setState(() => _drag = _at(d.localPosition.dx, w)),
            onHorizontalDragEnd: (_) {
              final target = _drag;
              setState(() => _drag = null);
              if (target != null) widget.onSeek(target);
            },
            onTapUp: (d) => widget.onSeek(_at(d.localPosition.dx, w)),
            child: SizedBox(
              height: 36,
              width: double.infinity,
              child: CustomPaint(
                  painter: _SliderPainter(frac, context.accent, _drag != null)),
            ),
          ),
        );
      },
    );
  }
}

class _SliderPainter extends CustomPainter {
  _SliderPainter(this.frac, this.color, this.dragging);
  final double frac;
  final Color color;
  final bool dragging;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    canvas.drawRect(
        Rect.fromLTWH(0, cy - 2, size.width, 4), Paint()..color = Mt.outline);
    canvas.drawRect(
        Rect.fromLTWH(0, cy - 2, size.width * frac, 4), Paint()..color = color);
    final tw = dragging ? 10.0 : 6.0;
    final th = dragging ? 26.0 : 16.0;
    final x =
        (size.width * frac - tw / 2).clamp(0.0, size.width - tw).toDouble();
    canvas.drawRect(
        Rect.fromLTWH(x, cy - th / 2, tw, th), Paint()..color = Mt.text);
  }

  @override
  bool shouldRepaint(_SliderPainter o) =>
      o.frac != frac || o.color != color || o.dragging != dragging;
}
