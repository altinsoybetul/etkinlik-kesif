import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const String _baseUrl = 'https://mobilab-task-api.vercel.app';
  static const Duration _timeout = Duration(seconds: 13);
  static const int pageSize = 10;

  // API bilerek ara sıra 500 hatası veriyor. Kullanıcıyı hemen hata ekranına
  // atmak yerine sunucu hatası ve zaman aşımında sessizce bir kez daha deniyoruz.
  static const int _maxAttempts = 2;

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Sayfalı etkinlik listesi. Arama ve kategori filtresi sunucuda yapılır,
  /// çünkü sayfalama varken sadece yüklenmiş öğelerde filtrelemek eksik sonuç verir.
  Future<EventPage> getEvents({
    int page = 1,
    String? query,
    String? category,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$pageSize',
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      'category': ?category,
    };
    final uri =
        Uri.parse('$_baseUrl/events').replace(queryParameters: params);

    final data = await _getJson(uri);
    final list = (data is Map ? data['items'] : data) as List? ?? [];
    final items = list
        .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return EventPage(
      items: items,
      page: page,
      total: data is Map ? (data['total'] as num?)?.toInt() ?? items.length : items.length,
      // hasMore gelmezse, tam sayfa geldiyse devamı olabilir diye varsayıyoruz.
      hasMore: data is Map
          ? data['hasMore'] == true
          : items.length == pageSize,
    );
  }

  Future<EventModel> getEventDetail(String id) async {
    final uri = Uri.parse('$_baseUrl/events/${Uri.encodeComponent(id)}');
    final data = await _getJson(uri);
    return EventModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<String>> getCategories() async {
    final data = await _getJson(Uri.parse('$_baseUrl/categories'));
    final list = (data is Map ? data['items'] : data) as List? ?? [];
    return list.map((c) => c.toString()).toList();
  }

  Future<dynamic> _getJson(Uri uri) async {
    ApiException? lastError;

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        final response = await _client.get(uri).timeout(_timeout);

        if (response.statusCode == 200) {
          return jsonDecode(utf8.decode(response.bodyBytes));
        }
        if (response.statusCode == 404) {
          throw ApiException('Etkinlik bulunamadı.');
        }
        lastError = ApiException(
            'Sunucu şu an yanıt veremiyor (kod ${response.statusCode}).');
        // 4xx hatalarında tekrar denemek işe yaramaz.
        if (response.statusCode < 500) break;
      } on TimeoutException {
        lastError =
            ApiException('Sunucu yanıt vermedi, bağlantı zaman aşımına uğradı.');
      } on http.ClientException {
        // İnternet yokken http paketi bu hatayı fırlatır; tekrar denemeye gerek yok.
        throw ApiException('İnternet bağlantınızı kontrol edin.');
      } on FormatException {
        throw ApiException('Sunucudan beklenmeyen bir yanıt geldi.');
      }

      if (attempt < _maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }

    throw lastError ?? ApiException('Veriler yüklenirken bir sorun oluştu.');
  }
}
