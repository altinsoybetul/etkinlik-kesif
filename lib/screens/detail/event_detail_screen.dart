import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/event_card_widget.dart';
import '../../widgets/favorite_button.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late EventModel _event = widget.event;
  // Favorilerden gelen kayıtta açıklama zaten saklanmış olabilir;
  // o zaman tekrar istek atmaya gerek yok.
  late bool _loading = widget.event.description == null;
  String? _error;

  @override
  void initState() {
    super.initState();
    // initState içinde setState çağrılamadığı için ilk yükleme durumunu
    // yukarıda alanın başlangıç değeriyle veriyoruz.
    if (_loading) _fetchDetail();
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final detail = await context.read<EventProvider>().fetchEventDetail(_event.id);
      if (!mounted) return;
      setState(() => _event = detail);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final event = _event;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? scheme.primaryContainer
                : scheme.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'event-image-${event.id}',
                    child: EventImage(url: event.imageUrl),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black26, Colors.transparent, Colors.black54],
                        stops: [0, 0.4, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              FavoriteButton(event: event, inactiveColor: Colors.white, size: 26),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(event.category),
                        backgroundColor: scheme.primaryContainer,
                        labelStyle: TextStyle(color: scheme.onPrimaryContainer),
                        side: BorderSide.none,
                      ),
                      Chip(
                        avatar: Icon(
                          event.isOnline ? Icons.wifi : Icons.groups_outlined,
                          size: 18,
                          color: scheme.onSecondaryContainer,
                        ),
                        label: Text(event.isOnline ? 'Online' : 'Yüz yüze'),
                        backgroundColor: scheme.secondaryContainer,
                        labelStyle: TextStyle(color: scheme.onSecondaryContainer),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(icon: Icons.calendar_month, text: DateFormatter.long(event)),
                  _InfoRow(icon: Icons.pin_drop_outlined, text: event.location),
                  if (event.organizer.isNotEmpty)
                    _InfoRow(icon: Icons.apartment_outlined, text: event.organizer),
                  if (event.capacity != null && event.registeredCount != null) ...[
                    const SizedBox(height: 8),
                    _CapacityBar(event: event),
                  ],
                  const Divider(height: 40),
                  const Text(
                    'Etkinlik Hakkında',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Açıklama gelince yükleniyor göstergesi yumuşakça yerini bıraksın.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _buildDescription(scheme),
                    ),
                  ),
                  if (event.tags.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: event.tags
                          .map((t) => Text('#$t',
                              style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              )))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(ColorScheme scheme) {
    if (_loading) {
      return const Padding(
        key: ValueKey('loading'),
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Row(
        key: const ValueKey('error'),
        children: [
          Icon(Icons.error_outline, color: scheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Açıklama yüklenemedi. $_error',
                style: TextStyle(color: scheme.error)),
          ),
          TextButton(onPressed: _retry, child: const Text('Tekrar Dene')),
        ],
      );
    }
    final text = _event.description;
    return Text(
      key: const ValueKey('text'),
      (text == null || text.isEmpty)
          ? 'Bu etkinlik için detaylı açıklama bulunmuyor.'
          : text,
      style: TextStyle(fontSize: 15, height: 1.5, color: scheme.onSurface),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapacityBar extends StatelessWidget {
  final EventModel event;

  const _CapacityBar({required this.event});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final capacity = event.capacity!;
    final registered = event.registeredCount!;
    final ratio = capacity == 0 ? 0.0 : (registered / capacity).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.isFull
              ? 'Kontenjan dolu ($registered/$capacity)'
              : '$registered/$capacity kişi kayıtlı · ${capacity - registered} yer kaldı',
          style: TextStyle(
            color: event.isFull ? scheme.error : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: ratio),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              color: event.isFull ? scheme.error : scheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
