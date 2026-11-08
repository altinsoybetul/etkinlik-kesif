import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../providers/event_provider.dart';
import '../theme/app_theme.dart';

class FavoriteButton extends StatefulWidget {
  final EventModel event;
  final Color? inactiveColor;
  final double size;

  const FavoriteButton({
    super.key,
    required this.event,
    this.inactiveColor,
    this.size = 22,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final isFav = provider.isFavorite(widget.event.id);

    return IconButton(
      tooltip: isFav ? 'Favorilerden çıkar' : 'Favorilere ekle',
      onPressed: () {
        if (!isFav) _controller.forward(from: 0);
        provider.toggleFavorite(widget.event);
      },
      icon: ScaleTransition(
        scale: _scale,
        child: Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          color: isFav
              ? AppTheme.favorite
              : widget.inactiveColor ??
                  Theme.of(context).colorScheme.onSurfaceVariant,
          size: widget.size,
        ),
      ),
    );
  }
}
