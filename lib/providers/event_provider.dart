import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class EventProvider with ChangeNotifier {
  static const String allCategories = 'Tümü';

  final ApiService _apiService;
  final StorageService _storageService;

  EventProvider({ApiService? apiService, StorageService? storageService})
      : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? StorageService();

  List<EventModel> _events = [];
  int _page = 0;
  bool _hasMore = true;
  bool _isLoading = false; // İlk sayfa yükleniyor (tam ekran yükleniyor)
  bool _isLoadingMore = false; // Sonraki sayfa yükleniyor (listenin altında)
  String? _errorMessage; // İlk sayfa hatası (tam ekran hata)
  String? _loadMoreError; // Sonraki sayfa hatası (liste kaybolmasın diye ayrı)

  // Her yeni aramada artar. Eski bir istek geç dönerse sonucunu yok sayarız;
  // yoksa "fl" aramasının cevabı "flutter" aramasının üstüne yazılabilir.
  int _requestId = 0;
  Timer? _debounce;

  String _searchQuery = '';
  String _selectedCategory = allCategories;
  List<String> _categories = [];

  List<EventModel> _favorites = [];

  List<EventModel> get events => _events;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String? get loadMoreError => _loadMoreError;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  List<String> get categories => [allCategories, ..._categories];
  List<EventModel> get favoriteEvents => List.unmodifiable(_favorites);

  /// Uygulama açılırken bir kez çağrılır.
  Future<void> init() async {
    _favorites = await _storageService.getFavorites();
    notifyListeners();
    await Future.wait([_loadCategories(), refresh()]);
  }

  Future<void> _loadCategories() async {
    try {
      _categories = await _apiService.getCategories();
      notifyListeners();
    } catch (_) {
      // Kategoriler gelmezse liste yine çalışır; çipleri yüklenen
      // etkinliklerden çıkarırız 
    }
  }

  void _fillCategoriesFromEvents() {
    if (_categories.isNotEmpty) return;
    final set = <String>{for (final e in _events) e.category}..remove('');
    _categories = set.toList()..sort();
  }

  /// Listeyi baştan yükler (ilk açılış, aşağı çekip yenileme, filtre değişimi)
  Future<void> refresh() async {
    final requestId = ++_requestId;
    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = null;
    _loadMoreError = null;
    notifyListeners();

    try {
      final result = await _fetchPage(1);
      if (requestId != _requestId) return; 
      _events = result.items;
      _page = 1;
      _hasMore = result.hasMore;
      _fillCategoriesFromEvents();
    } catch (e) {
      if (requestId != _requestId) return;
      _errorMessage = e.toString();
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Listenin sonuna gelince bir sonraki sayfayı ekler.
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    final requestId = _requestId;
    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    try {
      final result = await _fetchPage(_page + 1);
      if (requestId != _requestId) return;
      // Aynı etkinlik iki sayfada gelirse çift göstermemek için.
      final existing = _events.map((e) => e.id).toSet();
      _events = [
        ..._events,
        ...result.items.where((e) => !existing.contains(e.id)),
      ];
      _page = result.page;
      _hasMore = result.hasMore;
    } catch (e) {
      if (requestId != _requestId) return;
      _loadMoreError = e.toString();
    } finally {
      if (requestId == _requestId) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<EventPage> _fetchPage(int page) {
    return _apiService.getEvents(
      page: page,
      query: _searchQuery,
      category:
          _selectedCategory == allCategories ? null : _selectedCategory,
    );
  }

  /// Arama metni değiştikçe tetiklenir. Her harfte istek atmamak için
  /// kullanıcı yazmayı 400 ms bırakana kadar bekliyoruz
  void setSearchQuery(String query) {
    if (query == _searchQuery) return;
    _searchQuery = query;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), refresh);
  }

  void setCategory(String category) {
    if (category == _selectedCategory) return;
    _selectedCategory = category;
    _debounce?.cancel();
    refresh();
  }

  /// Detay ekranı için açıklamalı tam veriyi çeker.
  Future<EventModel> fetchEventDetail(String id) async {
    final detail = await _apiService.getEventDetail(id);
    // Favorideyse saklanan kopyayı açıklamalı haliyle güncelle.
    final index = _favorites.indexWhere((e) => e.id == id);
    if (index != -1) {
      _favorites[index] = detail;
      await _storageService.saveFavorites(_favorites);
    }
    return detail;
  }

  bool isFavorite(String eventId) => _favorites.any((e) => e.id == eventId);

  Future<void> toggleFavorite(EventModel event) async {
    if (isFavorite(event.id)) {
      _favorites.removeWhere((e) => e.id == event.id);
    } else {
      _favorites.insert(0, event); // En son eklenen en üstte.
    }
    // Önce ekranı güncelliyoruz ki kalp anında dolsun, sonra diske yazıyoruz.
    notifyListeners();
    await _storageService.saveFavorites(_favorites);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
