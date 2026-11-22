import 'package:material_ui/material_ui.dart';

import '../motion/motion.dart';
import '../theme/tokens.dart';

/// Panorama pivot: large lowercase headers where the next header peeks in and is
/// cropped at the right edge. Headers move slower than the content (parallax).
class MetroPivot extends StatefulWidget {
  const MetroPivot({
    super.key,
    required this.headers,
    required this.pages,
    this.style = Mt.header,
    this.initial = 0,
    this.gap = 24,
    this.onPage,
  }) : assert(headers.length == pages.length);

  final List<String> headers;
  final List<Widget> pages;
  final TextStyle style;
  final int initial;
  final double gap;
  final ValueChanged<int>? onPage;

  @override
  State<MetroPivot> createState() => _MetroPivotState();
}

class _MetroPivotState extends State<MetroPivot> {
  late final PageController _c = PageController(initialPage: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  List<double> _positions(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final xs = <double>[];
    var x = 0.0;
    for (final h in widget.headers) {
      xs.add(x);
      final tp = TextPainter(
        text: TextSpan(text: h, style: widget.style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      x += tp.width + widget.gap;
    }
    return xs;
  }

  @override
  Widget build(BuildContext context) {
    final xs = _positions(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final h =
        (widget.style.fontSize ?? 52) * (widget.style.height ?? 1.2) * scale;
    final n = widget.headers.length;
    return Column(
      children: [
        SizedBox(
          height: h,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final page = _c.hasClients && _c.position.haveDimensions
                    ? (_c.page ?? widget.initial.toDouble())
                    : widget.initial.toDouble();
                final lo = page.floor().clamp(0, n - 1).toInt();
                final hi = page.ceil().clamp(0, n - 1).toInt();
                final off = xs[lo] + (xs[hi] - xs[lo]) * (page - lo);
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    for (var i = 0; i < n; i++)
                      Positioned(
                        left: Mt.pad + xs[i] - off,
                        top: 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _c.animateToPage(
                            i,
                            duration: MotionTokens.pivot,
                            curve: MotionTokens.curve,
                          ),
                          child: Semantics(
                            header: true,
                            child: Text(
                              widget.headers[i],
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: widget.style.copyWith(
                                color: Color.lerp(
                                  Mt.dim,
                                  Mt.text,
                                  (1 - (page - i).abs())
                                      .clamp(0.0, 1.0)
                                      .toDouble(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        Expanded(
          child: PageView(
            controller: _c,
            onPageChanged: widget.onPage,
            children: widget.pages,
          ),
        ),
      ],
    );
  }
}
