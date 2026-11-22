import 'dart:math';

import 'package:material_ui/material_ui.dart';

class EqualizerBars extends StatefulWidget {
  const EqualizerBars({
    super.key,
    required this.isPlaying,
    this.barCount = 4,
    this.width = 22,
    this.height = 22,
    this.gap = 2,
    this.color = Colors.white,
    this.levels,
  });

  final bool isPlaying;
  final int barCount;
  final double width;
  final double height;
  final double gap;
  final Color color;
  final List<double>? levels;

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final AnimationController _gain = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  late List<double> _phase;
  late List<int> _speed;

  @override
  void initState() {
    super.initState();
    _updatePattern();
    if (widget.isPlaying) {
      _gain.value = 1;
      _loop.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.barCount != oldWidget.barCount) _updatePattern();
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _loop.repeat();
        _gain.forward();
      } else {
        _loop.stop();
        _gain.reverse();
      }
    }
  }

  void _updatePattern() {
    final random = Random(7);
    _phase = List.generate(widget.barCount, (_) => random.nextDouble());
    _speed = List.generate(widget.barCount, (i) => 1 + (i * 2 + 1) % 3);
  }

  @override
  void dispose() {
    _loop.dispose();
    _gain.dispose();
    super.dispose();
  }

  double _level(int index, double time) {
    final levels = widget.levels;
    if (levels != null && levels.isNotEmpty) {
      return levels[index % levels.length].clamp(0.0, 1.0).toDouble();
    }

    final speed = _speed[index];
    final phase = _phase[index];
    final first = 0.5 + 0.5 * sin(2 * pi * (time * speed + phase));
    final second = 0.5 + 0.5 * sin(2 * pi * (time * (speed + 1) + phase * 2));
    return 0.65 * first + 0.35 * second;
  }

  @override
  Widget build(BuildContext context) {
    const minFraction = 0.14;
    final barWidth =
        (widget.width - widget.gap * (widget.barCount - 1)) / widget.barCount;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: Listenable.merge([_loop, _gain]),
        builder: (context, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < widget.barCount; i++) ...[
              if (i > 0) SizedBox(width: widget.gap),
              Container(
                width: barWidth,
                height: widget.height *
                    (minFraction +
                        (1 - minFraction) *
                            _level(i, _loop.value) *
                            _gain.value),
                color: widget.color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
