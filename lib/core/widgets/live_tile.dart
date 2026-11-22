import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../motion/motion.dart';
import '../theme/tokens.dart';
import 'pressable.dart';

/// Tile footprints on a four-column start screen.
enum TileSize { small, medium, wide }

extension TileSizeX on TileSize {
  int get cols => switch (this) {
        TileSize.small => 1,
        TileSize.medium => 2,
        TileSize.wide => 4,
      };
  int get rows => switch (this) {
        TileSize.small => 1,
        TileSize.medium => 2,
        TileSize.wide => 2,
      };
}

enum TileAnimation { flip, slide, fade }

/// Description of one live tile.
///
/// [builder] is called with a face counter that increases on every flip, so a
/// tile can walk through fresh album art each time it turns over.
class LiveTileSpec {
  const LiveTileSpec({
    required this.id,
    required this.size,
    required this.builder,
    this.animation = TileAnimation.flip,
    this.onTap,
    this.label,
    this.animate = true,
  });

  final String id;
  final TileSize size;
  final Widget Function(BuildContext context, int face) builder;
  final TileAnimation animation;
  final VoidCallback? onTap;
  final String? label;

  /// Static tiles never register with the scheduler, so they never flip.
  final bool animate;
}

class _Placement {
  const _Placement(this.spec, this.col, this.row);
  final LiveTileSpec spec;
  final int col;
  final int row;
}

List<_Placement> _pack(List<LiveTileSpec> specs, int columns) {
  final occupied = <List<bool>>[];

  void grow(int rows) {
    while (occupied.length < rows) {
      occupied.add(List<bool>.filled(columns, false));
    }
  }

  bool fits(int c, int r, int w, int h) {
    if (c + w > columns) return false;
    for (var y = r; y < r + h; y++) {
      if (y >= occupied.length) continue;
      for (var x = c; x < c + w; x++) {
        if (occupied[y][x]) return false;
      }
    }
    return true;
  }

  final out = <_Placement>[];
  for (final spec in specs) {
    final w = spec.size.cols;
    final h = spec.size.rows;
    var row = 0;
    var placed = false;
    while (!placed) {
      for (var c = 0; c <= columns - w; c++) {
        if (fits(c, row, w, h)) {
          grow(row + h);
          for (var y = row; y < row + h; y++) {
            for (var x = c; x < c + w; x++) {
              occupied[y][x] = true;
            }
          }
          out.add(_Placement(spec, c, row));
          placed = true;
          break;
        }
      }
      row++;
    }
  }
  return out;
}

/// Fires one random tile at a time, never the same tile twice in a row.
class LiveTileScheduler {
  LiveTileScheduler({
    this.minGap = const Duration(milliseconds: 2600),
    this.maxGap = const Duration(milliseconds: 5200),
    math.Random? rng,
  }) : _rng = rng ?? math.Random();

  final Duration minGap;
  final Duration maxGap;
  final math.Random _rng;

  final Map<String, VoidCallback> _tiles = {};
  Timer? _timer;
  String? _last;
  bool _paused = true;

  void register(String id, VoidCallback flip) => _tiles[id] = flip;
  void unregister(String id) => _tiles.remove(id);

  void start() {
    if (!_paused) return;
    _paused = false;
    _schedule();
  }

  void pause() {
    _paused = true;
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    pause();
    _tiles.clear();
  }

  void _schedule() {
    _timer?.cancel();
    final span = maxGap.inMilliseconds - minGap.inMilliseconds;
    final delay =
        minGap + Duration(milliseconds: span <= 0 ? 0 : _rng.nextInt(span));
    _timer = Timer(delay, () {
      if (_paused) return;
      _fire();
      _schedule();
    });
  }

  void _fire() {
    if (_tiles.isEmpty) return;
    final ids = _tiles.keys.toList();
    if (ids.length > 1 && _last != null) ids.remove(_last);
    final id = ids[_rng.nextInt(ids.length)];
    _last = id;
    _tiles[id]?.call();
  }
}

/// A four-column start screen: mixed tile sizes, packed like Windows Phone,
/// with a turnstile entrance and one tile animating at a time.
class LiveTileGrid extends StatefulWidget {
  const LiveTileGrid({
    super.key,
    required this.tiles,
    this.columns = 4,
    this.gap = 8,
  });

  final List<LiveTileSpec> tiles;
  final int columns;
  final double gap;

  @override
  State<LiveTileGrid> createState() => _LiveTileGridState();
}

class _LiveTileGridState extends State<LiveTileGrid>
    with WidgetsBindingObserver {
  final LiveTileScheduler _scheduler = LiveTileScheduler();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduce(context)) {
      _scheduler.pause();
    } else {
      _scheduler.start();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduler.start();
    } else {
      _scheduler.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scheduler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placements = _pack(widget.tiles, widget.columns);
    var rows = 0;
    for (final p in placements) {
      rows = math.max(rows, p.row + p.spec.size.rows);
    }

    return LayoutBuilder(
      builder: (context, box) {
        final unit =
            (box.maxWidth - widget.gap * (widget.columns - 1)) / widget.columns;
        final step = unit + widget.gap;
        final height = rows == 0 ? 0.0 : rows * unit + (rows - 1) * widget.gap;
        final reduce = Motion.reduce(context);
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              for (final p in placements)
                Positioned(
                  left: p.col * step,
                  top: p.row * step,
                  width: p.spec.size.cols * unit +
                      (p.spec.size.cols - 1) * widget.gap,
                  height: p.spec.size.rows * unit +
                      (p.spec.size.rows - 1) * widget.gap,
                  child: LiveTile(
                    key: ValueKey(p.spec.id),
                    spec: p.spec,
                    scheduler: _scheduler,
                    entrance: reduce
                        ? Duration.zero
                        : Duration(milliseconds: (p.row + p.col) * 70),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class LiveTile extends StatefulWidget {
  const LiveTile({
    super.key,
    required this.spec,
    required this.scheduler,
    this.entrance = Duration.zero,
  });

  final LiveTileSpec spec;
  final LiveTileScheduler scheduler;
  final Duration entrance;

  @override
  State<LiveTile> createState() => _LiveTileState();
}

class _LiveTileState extends State<LiveTile> with TickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  Timer? _enterTimer;
  int _face = 0;
  int _next = 0;

  @override
  void initState() {
    super.initState();
    if (widget.spec.animate) {
      widget.scheduler.register(widget.spec.id, _turn);
    }
    if (widget.entrance == Duration.zero) {
      _enter.value = 1;
    } else {
      _enterTimer = Timer(widget.entrance, () {
        if (mounted) _enter.forward();
      });
    }
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    if (widget.spec.animate) {
      widget.scheduler.unregister(widget.spec.id);
    }
    _flip.dispose();
    _enter.dispose();
    super.dispose();
  }

  Future<void> _turn() async {
    if (!mounted || _flip.isAnimating || _enter.isAnimating) return;
    setState(() => _next = _face + 1);
    await _flip.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _face = _next;
      _flip.value = 0;
    });
  }

  Widget _content(BuildContext context) {
    final from = widget.spec.builder(context, _face);
    if (_flip.value == 0) return from;
    final to = widget.spec.builder(context, _next);
    final t = Curves.easeInOut.transform(_flip.value);
    switch (widget.spec.animation) {
      case TileAnimation.flip:
        final firstHalf = t < 0.5;
        final angle = firstHalf ? t * math.pi : (t - 1) * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateX(angle),
          child: firstHalf ? from : to,
        );
      case TileAnimation.slide:
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              FractionalTranslation(
                translation: Offset(0, -t),
                child: from,
              ),
              FractionalTranslation(
                translation: Offset(0, 1 - t),
                child: to,
              ),
            ],
          ),
        );
      case TileAnimation.fade:
        return Stack(
          fit: StackFit.expand,
          children: [
            from,
            Opacity(opacity: t, child: to),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_flip, _enter]),
      builder: (context, _) {
        final e = Curves.easeOutCubic.transform(_enter.value);
        return Opacity(
          opacity: e,
          child: Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(-(1 - e) * math.pi / 2),
            child: Pressable(
              label: widget.spec.label,
              onTap: widget.spec.onTap,
              child: ClipRect(child: _content(context)),
            ),
          ),
        );
      },
    );
  }
}

/// Shared darkening gradient so tile text stays readable over album art.
class TileShade extends StatelessWidget {
  const TileShade({super.key, this.color, this.opacity = 0.34});

  final Color? color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Mt.bg;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tint.withValues(alpha: opacity),
            Colors.black.withValues(alpha: 0.16),
            Colors.black.withValues(alpha: 0.82),
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
    );
  }
}

/// Small uppercase tile caption with a shadow for contrast.
class TileCaption extends StatelessWidget {
  const TileCaption(
    this.text, {
    super.key,
    this.size = 17,
    this.weight = FontWeight.w400,
  });

  final String text;
  final double size;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: Mt.sans,
        fontSize: size,
        fontWeight: weight,
        color: Mt.text,
        shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
      ),
    );
  }
}
