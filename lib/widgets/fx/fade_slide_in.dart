import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';

/// A reusable entrance animation: fades in while gently sliding up.
///
/// Wrap any widget to have it compose in elegantly when the screen mounts.
/// Use [delay] to stagger a sequence of items (see [AppMotion.staggerDelay]).
///
/// ```dart
/// FadeSlideIn(delay: AppMotion.staggerDelay(index), child: card)
/// ```
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.slow,
    this.offset = 0.06,
    this.curve = AppMotion.entrance,
  });

  final Widget child;

  /// Delay before the animation starts (use for staggering).
  final Duration delay;

  /// How long the fade/slide takes.
  final Duration duration;

  /// Vertical slide distance as a fraction of the child's height.
  final double offset;

  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);

  late final Animation<double> _opacity =
      CurvedAnimation(parent: _controller, curve: widget.curve);

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(0, widget.offset),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
