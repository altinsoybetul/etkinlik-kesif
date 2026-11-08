import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/event_model.dart';
import '../screens/detail/event_detail_screen.dart';
import '../utils/date_formatter.dart';
import 'favorite_button.dart';

class EventCardWidget extends StatelessWidget {
  final EventModel event;

  const EventCardWidget({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final secondaryText = TextStyle(color: scheme.onSurfaceVariant, fontSize: 13);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim, kategori rozeti ve kalp butonu
            Stack(
              children: [
                Hero(
                  tag: 'event-image-${event.id}',
                  child: EventImage(url: event.imageUrl, height: 160),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: [
                      _Badge(text: event.category, color: scheme.primary, textColor: scheme.onPrimary),
                      if (event.isOnline) ...[
                        const SizedBox(width: 6),
                        _Badge(
                          text: 'Online',
                          color: scheme.tertiary,
                          textColor: scheme.onTertiary,
                          icon: Icons.wifi,
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: scheme.surface.withValues(alpha: 0.9),
                    radius: 20,
                    child: FavoriteButton(event: event),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: scheme.primary),
                      const SizedBox(width: 4),
                      Text(DateFormatter.short(event), style: secondaryText),
                      if (event.isFull) ...[
                        const Spacer(),
                        Text(
                          'Kontenjan dolu',
                          style: TextStyle(
                            color: scheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: scheme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventImage extends StatelessWidget {
  final String url;
  final double? height;

  const EventImage({super.key, required this.url, this.height});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget placeholder(IconData icon) => Container(
          height: height,
          width: double.infinity,
          color: scheme.primaryContainer,
          child: Icon(icon, size: 48, color: scheme.onPrimaryContainer.withValues(alpha: 0.5)),
        );

    if (url.isEmpty) return placeholder(Icons.event);

    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (context, url) => Container(
        height: height,
        color: scheme.surfaceContainerHighest,
      ),
      errorWidget: (context, url, error) => placeholder(Icons.broken_image_outlined),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final IconData? icon;

  const _Badge({required this.text, required this.color, required this.textColor, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
