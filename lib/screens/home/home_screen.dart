import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../widgets/event_card_widget.dart';
import '../../widgets/fade_in_slide.dart';
import '../../widgets/status_view.dart';
import '../../widgets/theme_toggle_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _searchController;

  // Giriş animasyonunu sadece ilk kez görünen kartlarda oynatıyoruz;
  // yukarı kaydırıp geri gelince kartlar tekrar tekrar zıplamasın.
  final Set<String> _animatedIds = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<EventProvider>().searchQuery,
    );
  }

  // Sonsuz kaydırma: listenin sonuna 300 px kala bir sonraki sayfayı iste
  bool _onScroll(ScrollNotification notification) {
    final provider = context.read<EventProvider>();
    // Hata varsa her kaydırmada tekrar istek atmayalım; kullanıcı
    // "Tekrar Dene"ye bassın.
    if (notification.metrics.axis == Axis.vertical &&
        notification.metrics.extentAfter < 300 &&
        provider.loadMoreError == null) {
      provider.loadMore();
    }
    return false; // Bildirim RefreshIndicator'a da ulaşsın.
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters(EventProvider provider) {
    _searchController.clear();
    provider.setSearchQuery('');
    provider.setCategory(EventProvider.allCategories);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etkinlikleri Keşfet'),
        actions: const [ThemeToggleButton(), SizedBox(width: 4)],
      ),
      body: Column(
        children: [
          // 1. Arama çubuğu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                provider.setSearchQuery(val);
                setState(() {}); // Temizle butonunun görünürlüğü için.
              },
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Etkinlik veya etiket ara...',
                prefixIcon: Icon(Icons.search, color: scheme.primary),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Aramayı temizle',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),

          // 2. Kategori çipleri
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: provider.categories.length,
              itemBuilder: (context, index) {
                final cat = provider.categories[index];
                final isSelected = cat == provider.selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: (_) => provider.setCategory(cat),
                    labelStyle: TextStyle(
                      color: isSelected ? scheme.onPrimary : scheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // durumlar arasında yumuşak geçiş için AnimatedSwitcher.
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildContent(provider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(EventProvider provider) {
    if (provider.isLoading && provider.events.isEmpty) {
      return const StatusView.loading(
        key: ValueKey('loading'),
        message: 'Etkinlikler yükleniyor...',
      );
    }

    if (provider.errorMessage != null) {
      return StatusView(
        key: const ValueKey('error'),
        icon: Icons.cloud_off_rounded,
        isError: true,
        message: provider.errorMessage!,
        actionLabel: 'Tekrar Dene',
        onAction: provider.refresh,
      );
    }

    if (provider.events.isEmpty) {
      final hasFilter = provider.searchQuery.isNotEmpty ||
          provider.selectedCategory != EventProvider.allCategories;
      return StatusView(
        key: const ValueKey('empty'),
        icon: Icons.event_busy_rounded,
        message: hasFilter
            ? 'Aradığınız kriterlere uygun etkinlik bulunamadı.'
            : 'Şu an listelenecek etkinlik yok.',
        actionLabel: hasFilter ? 'Filtreleri Temizle' : null,
        onAction: hasFilter ? () => _clearFilters(provider) : null,
      );
    }

    return RefreshIndicator(
      key: const ValueKey('list'),
      onRefresh: provider.refresh,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: ListView.builder(
              key: const PageStorageKey('home-list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 16),
              // +1: listenin sonundaki "yükleniyor / daha fazla / bitti" satırı
              itemCount: provider.events.length + 1,
              itemBuilder: (context, index) {
                if (index == provider.events.length) {
                  return _ListFooter(provider: provider);
                }
                final event = provider.events[index];
                final isNew = _animatedIds.add(event.id);
                return FadeInSlide(
                  key: ValueKey(event.id),
                  animate: isNew,
                  // Aynı sayfadaki kartlar sırayla gelsin (en fazla ~0.3 sn).
                  delay: Duration(milliseconds: isNew ? (index % 10) * 30 : 0),
                  child: EventCardWidget(event: event),
                );
              },
            ),
          ),
          if (provider.isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  final EventProvider provider;

  const _ListFooter({required this.provider});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget child;
    if (provider.isLoadingMore) {
      child = const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    } else if (provider.loadMoreError != null) {
      // Sonraki sayfa hata verirse yüklenmiş liste kaybolmasın; burada tekrar dene.
      child = Column(
        children: [
          Text(
            provider.loadMoreError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.error),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: provider.loadMore,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
          ),
        ],
      );
    } else if (provider.hasMore) {
      // Kaydırma kendiliğinden tetiklemezse (ör. büyük ekran) elle yükleme.
      child = TextButton(
        onPressed: provider.loadMore,
        child: const Text('Daha fazla yükle'),
      );
    } else {
      child = Text(
        'Tüm etkinlikleri gördün 🎉',
        style: TextStyle(color: scheme.onSurfaceVariant),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Center(child: child),
    );
  }
}
