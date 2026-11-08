import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../widgets/event_card_widget.dart';
import '../../widgets/status_view.dart';
import '../../widgets/theme_toggle_button.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    // Favoriler cihazda tam haliyle saklandığı için internet olmasa da listelenir.
    final favEvents = provider.favoriteEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorilerim'),
        actions: const [ThemeToggleButton(), SizedBox(width: 4)],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: favEvents.isEmpty
            ? const StatusView(
                key: ValueKey('empty'),
                icon: Icons.favorite_border,
                message: 'Henüz favorilere etkinlik eklemediniz.\n'
                    'Beğendiğin etkinliklerdeki kalbe dokun.',
              )
            : ListView.builder(
                key: const ValueKey('list'),
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: favEvents.length,
                itemBuilder: (context, index) {
                  return EventCardWidget(
                    key: ValueKey(favEvents[index].id),
                    event: favEvents[index],
                  );
                },
              ),
      ),
    );
  }
}
