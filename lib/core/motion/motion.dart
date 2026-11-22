import 'package:material_ui/material_ui.dart';

abstract final class MotionTokens {
  static const turnIn = Duration(milliseconds: 300);
  static const turnOut = Duration(milliseconds: 200);
  static const slideUp = Duration(milliseconds: 280);
  static const pressDown = Duration(milliseconds: 80);
  static const pressUp = Duration(milliseconds: 160);
  static const stagger = Duration(milliseconds: 40);
  static const pivot = Duration(milliseconds: 280);
  static const art = Duration(milliseconds: 250);
  static const fade = Duration(milliseconds: 120);
  static const curve = Curves.easeOutCubic;
  static const maxStaggered = 12;
}

abstract final class Motion {
  /// 0 = follow system, 1 = reduce, 2 = full motion. Set from settings.
  static int mode = 0;

  static bool reduce(BuildContext c) =>
      mode == 1 || (mode == 0 && MediaQuery.disableAnimationsOf(c));
}

/// Slides and fades a child in, delayed by [index]. Only the first
/// [MotionTokens.maxStaggered] items animate; reduced motion skips it.
class StaggerIn extends StatefulWidget {
  const StaggerIn({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
  bool _started = false;
  bool _skip = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _skip = widget.index >= MotionTokens.maxStaggered || Motion.reduce(context);
    if (_skip) {
      _c.value = 1;
    } else {
      Future<void>.delayed(MotionTokens.stagger * widget.index, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_skip) return widget.child;
    final a = CurvedAnimation(parent: _c, curve: MotionTokens.curve);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.12, 0), end: Offset.zero)
            .animate(a),
        child: widget.child,
      ),
    );
  }
}
