import 'package:event_app/models/event_model.dart';
import 'package:event_app/services/api_service.dart';

/// İnternete çıkmadan test yapabilmek için sahte API.
/// Gerçek API gibi 10'arlı sayfa döner; istenirse hata fırlatır.
class FakeApiService extends ApiService {
  final List<EventModel> all;
  bool shouldFail = false;
  final List<Map<String, dynamic>> calls = [];

  FakeApiService({int count = 25})
      : all = List.generate(
          count,
          (i) => EventModel(
            id: 'evt-$i',
            title: i.isEven ? 'Flutter Atölyesi $i' : 'Kariyer Paneli $i',
            location: 'Kampüs',
            date: '2026-10-21T18:00:00+03:00',
            category: i.isEven ? 'Workshop' : 'Panel',
            imageUrl: '', // Testte ağdan resim indirmeye çalışmasın.
            organizer: 'MOBILAB',
          ),
        );

  @override
  Future<EventPage> getEvents({int page = 1, String? query, String? category}) async {
    calls.add({'page': page, 'q': query, 'category': category});
    if (shouldFail) throw ApiException('Sunucu şu an yanıt veremiyor.');

    final filtered = all.where((e) {
      final q = query?.toLowerCase() ?? '';
      return e.title.toLowerCase().contains(q) &&
          (category == null || e.category == category);
    }).toList();

    const size = ApiService.pageSize;
    final start = (page - 1) * size;
    final items = filtered.skip(start).take(size).toList();
    return EventPage(
      items: items,
      page: page,
      total: filtered.length,
      hasMore: start + size < filtered.length,
    );
  }

  @override
  Future<List<String>> getCategories() async => ['Panel', 'Workshop'];

  @override
  Future<EventModel> getEventDetail(String id) async {
    final e = all.firstWhere((e) => e.id == id);
    return EventModel.fromJson({...e.toJson(), 'description': 'Açıklama $id'});
  }
}
