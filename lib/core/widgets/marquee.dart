import 'package:material_ui/material_ui.dart';

import '../motion/motion.dart';

/// Single-line text that scrolls sideways when it does not fit.
class MarqueeText extends StatefulWidget {
  const MarqueeText(this.text, {super.key, required this.style});
  final String text;
  final TextStyle style;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  final _c = ScrollController();
  bool _running = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _loop() async {
    if (_running) return;
    _running = true;
    while (mounted) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted || !_c.hasClients) break;
      final max = _c.position.maxScrollExtent;
      if (max <= 0) break;
      await _c.animateTo(max,
          duration: Duration(milliseconds: (max * 30).round()),
          curve: Curves.linear);
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted || !_c.hasClients) break;
      _c.jumpTo(0);
    }
    _running = false;
  }

  @override
  Widget build(BuildContext context) {
    final plain = Text(widget.text,
        maxLines: 1, overflow: TextOverflow.ellipsis, style: widget.style);
    if (Motion.reduce(context)) return plain;
    return LayoutBuilder(
      builder: (context, box) {
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        if (tp.width <= box.maxWidth) return plain;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loop();
        });
        return SingleChildScrollView(
          controller: _c,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Text(widget.text,
              maxLines: 1, softWrap: false, style: widget.style),
        );
      },
    );
  }
}
