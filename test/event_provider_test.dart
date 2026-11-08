import 'package:event_app/models/event_model.dart';
import 'package:event_app/providers/event_provider.dart';
import 'package:event_app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_api_service.dart';

void main() {
  late FakeApiService api;
  late EventProvider provider;

  setUp(() {
    // SharedPreferences'ı bellekte çalıştır (gerçek diske yazmaz).
    SharedPreferences.setMockInitialValues({});
    api = FakeApiService(count: 25);
    provider = EventProvider(apiService: api);
  });

  group('Model', () {
    test('API JSON\'ını doğru okur', () {
      final e = EventModel.fromJson({
        'id': 'evt-001',
        'title': 'Flutter',
        'category': 'Workshop',
        'startDate': '2026-10-21T18:00:00+03:00',
        'location': 'B-112',
        'organizer': 'MOBILAB',
        'imageUrl': 'https://x',
        'capacity': 60,
        'registeredCount': 60,
        'isOnline': true,
        'tags': ['flutter', 'mobil'],
      });
      expect(e.date, '2026-10-21T18:00:00+03:00');
      expect(e.description, isNull); // Liste yanıtında açıklama yok.
      expect(e.isOnline, isTrue);
      expect(e.isFull, isTrue);
      expect(e.tags, ['flutter', 'mobil']);
    });

    test('toJson → fromJson aynı veriyi verir (favori saklama için)', () {
      final e = api.all.first;
      final copy = EventModel.fromJson(e.toJson());
      expect(copy.id, e.id);
      expect(copy.title, e.title);
      expect(copy.category, e.category);
    });
  });

  group('Sayfalama', () {
    test('ilk sayfa 10 etkinlik getirir, devamı olduğunu bilir', () async {
      await provider.refresh();
      expect(provider.events.length, 10);
      expect(provider.hasMore, isTrue);
      expect(provider.errorMessage, isNull);
    });

    test('loadMore sonraki sayfaları ekler ve sonda durur', () async {
      await provider.refresh();
      await provider.loadMore();
      expect(provider.events.length, 20);
      await provider.loadMore();
      expect(provider.events.length, 25);
      expect(provider.hasMore, isFalse);

      await provider.loadMore(); // Daha fazla yok: istek atmamalı.
      expect(api.calls.length, 3);
    });

    test('ilk sayfa hata verirse hata mesajı tutulur', () async {
      api.shouldFail = true;
      await provider.refresh();
      expect(provider.errorMessage, isNotNull);
      expect(provider.events, isEmpty);
    });

    test('sonraki sayfa hata verirse yüklenmiş liste korunur', () async {
      await provider.refresh();
      api.shouldFail = true;
      await provider.loadMore();
      expect(provider.events.length, 10);
      expect(provider.loadMoreError, isNotNull);
      expect(provider.errorMessage, isNull);
    });
  });

  group('Filtreleme', () {
    test('kategori seçimi sunucuya parametre olarak gider', () async {
      provider.setCategory('Workshop');
      await Future<void>.delayed(Duration.zero);
      expect(api.calls.last['category'], 'Workshop');
      expect(provider.events.every((e) => e.category == 'Workshop'), isTrue);
    });

    test('arama 400 ms bekledikten sonra tek istek atar (debounce)', () async {
      await provider.refresh();
      final before = api.calls.length;
      provider.setSearchQuery('F');
      provider.setSearchQuery('Fl');
      provider.setSearchQuery('Flutter');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(api.calls.length, before + 1);
      expect(api.calls.last['q'], 'Flutter');
    });
  });

  group('Favoriler', () {
    test('favori eklenir, çıkarılır ve diske yazılır', () async {
      final event = api.all.first;
      await provider.toggleFavorite(event);
      expect(provider.isFavorite(event.id), isTrue);

      // Uygulama kapanıp açılmış gibi: yeni bir servisle diskten oku.
      final saved = await StorageService().getFavorites();
      expect(saved.map((e) => e.id), [event.id]);

      await provider.toggleFavorite(event);
      expect(provider.isFavorite(event.id), isFalse);
      expect(await StorageService().getFavorites(), isEmpty);
    });

    test('uygulama yeniden açılınca favoriler geri yüklenir', () async {
      await provider.toggleFavorite(api.all[3]);

      final reopened = EventProvider(apiService: FakeApiService());
      await reopened.init();
      expect(reopened.favoriteEvents.single.id, 'evt-3');
    });
  });
}
