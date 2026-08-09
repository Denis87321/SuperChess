import 'package:flutter/material.dart';

/// Shared looping ticker for idle VFX overlays.
class FxHost extends StatefulWidget {
  const FxHost({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 1800),
    this.enabled = true,
  });

  final Widget Function(BuildContext context, double t) builder;
  final Duration duration;
  final bool enabled;

  @override
  State<FxHost> createState() => _FxHostState();
}

class _FxHostState extends State<FxHost> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    if (widget.enabled) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant FxHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.enabled && _c.isAnimating) {
      _c.stop();
    }
    if (oldWidget.duration != widget.duration) {
      _c.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.builder(context, 0);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => widget.builder(context, _c.value),
    );
  }
}
