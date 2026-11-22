import 'dart:async';

import 'package:material_ui/material_ui.dart';

class NowPlayingCarousel extends StatefulWidget {
  const NowPlayingCarousel({
    super.key,
    required this.currentIndex,
    required this.itemCount,
    required this.artworkBuilder,
    required this.onIndexChanged,
    required this.onTap,
  })  : assert(itemCount > 0),
        assert(currentIndex >= 0 && currentIndex < itemCount);

  final int currentIndex;
  final int itemCount;
  final Widget Function(int index) artworkBuilder;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onTap;

  @override
  State<NowPlayingCarousel> createState() => _NowPlayingCarouselState();
}

class _NowPlayingCarouselState extends State<NowPlayingCarousel> {
  late final PageController _pageController = PageController(
    viewportFraction: 0.78,
    initialPage: widget.currentIndex,
  );
  bool _programmatic = false;
  int _animationGeneration = 0;

  @override
  void didUpdateWidget(covariant NowPlayingCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _animateToCurrentPage();
      });
    }
  }

  void _animateToCurrentPage() {
    if (!_pageController.hasClients ||
        !_pageController.position.haveDimensions) {
      return;
    }
    final page = _pageController.page;
    if (page == null || page.round() == widget.currentIndex) return;

    final generation = ++_animationGeneration;
    _programmatic = true;
    unawaited(_animateTo(widget.currentIndex, generation));
  }

  Future<void> _animateTo(int index, int generation) async {
    try {
      await _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } finally {
      if (mounted && generation == _animationGeneration) {
        _programmatic = false;
      }
    }
  }

  bool _handleScrollEnd(ScrollEndNotification notification) {
    if (notification.depth == 0 &&
        !_programmatic &&
        _pageController.hasClients &&
        _pageController.position.haveDimensions) {
      final index = _pageController.page?.round();
      if (index != null &&
          index >= 0 &&
          index < widget.itemCount &&
          index != widget.currentIndex) {
        widget.onIndexChanged(index);
      }
    }
    return false;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollEndNotification>(
      onNotification: _handleScrollEnd,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.itemCount,
        itemBuilder: (context, index) => AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            final page = _pageController.hasClients &&
                    _pageController.position.haveDimensions
                ? _pageController.page ?? widget.currentIndex.toDouble()
                : widget.currentIndex.toDouble();
            final distance = (page - index).abs().clamp(0.0, 1.0).toDouble();
            return Center(
              child: Opacity(
                opacity: 1 - 0.55 * distance,
                child: Transform.scale(
                  scale: 1 - 0.1 * distance,
                  child: child,
                ),
              ),
            );
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (index == widget.currentIndex) {
                widget.onTap();
              } else {
                widget.onIndexChanged(index);
              }
            },
            child: AspectRatio(
              aspectRatio: 1,
              child: widget.artworkBuilder(index),
            ),
          ),
        ),
      ),
    );
  }
}
