import 'package:material_ui/material_ui.dart';

import '../motion/motion.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.dart';

/// Tap target with the Metro press effect: scale to 0.96 and tilt toward the
/// touch point. Honours reduced motion.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.label,
    this.tilt = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? label;
  final bool tilt;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  Alignment _at = Alignment.center;

  void _press(TapDownDetails d) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.isEmpty) return;
    final s = box.size;
    setState(() {
      _down = true;
      _at = Alignment(
        (d.localPosition.dx / s.width) * 2 - 1,
        (d.localPosition.dy / s.height) * 2 - 1,
      );
    });
  }

  void _release() {
    if (_down) setState(() => _down = false);
  }

  Matrix4 _matrix(BuildContext context) {
    if (!_down || Motion.reduce(context)) return Matrix4.identity();
    final m = Matrix4.identity()..setEntry(3, 2, 0.002);
    if (widget.tilt) {
      m.rotateX(-_at.y * 0.05);
      m.rotateY(_at.x * 0.05);
    }
    m.scaleByDouble(0.96, 0.96, 1.0, 1.0);
    return m;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: widget.label != null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _press,
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: _down ? MotionTokens.pressDown : MotionTokens.pressUp,
          curve: Curves.easeOut,
          transform: _matrix(context),
          transformAlignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 2 px outline circle button (44 dp minimum, 48 dp preferred).
class CircleButton extends StatelessWidget {
  const CircleButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.child,
    this.size = 48,
    this.iconSize,
    this.color = Mt.text,
  }) : assert(icon != null || child != null);

  final String label;
  final VoidCallback? onTap;
  final String? icon;
  final Widget? child;
  final double size;
  final double? iconSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label: label,
      onTap: onTap,
      tilt: false,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: child ??
                MetroIcon(icon!, size: iconSize ?? size * 0.42, color: color),
          ),
        ),
      ),
    );
  }
}
