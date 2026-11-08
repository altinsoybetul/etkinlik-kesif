import 'package:flutter/material.dart';

class FadeInSlide extends StatefulWidget {
  final Widget child;
  final bool animate;
  final Duration delay;

  const FadeInSlide({
    super.key,
    required this.child,
    this.animate = true,
    this.delay = Duration.zero,
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 350);

  // Gecikmeyi ayrı bir zamanlayıcı yerine animasyonun içine koyuyoruz:
  // Böylece widget kapanırsa ortada çalışan bir Timer kalmıyor.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration + widget.delay,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMilliseconds / (_duration + widget.delay).inMilliseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1; // Zaten görülmüş kart: animasyonsuz göster.
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
      opacity: _curve,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(_curve),
        child: widget.child,
      ),
    );
  }
}
