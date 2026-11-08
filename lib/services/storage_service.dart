import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';

class StorageService {
  // Favorilerin sadece id'sini değil, etkinliğin kendisini saklıyoruz.
  // Sebep: Sayfalama gelince bir favori henüz yüklenmemiş bir sayfada olabilir;
  // sadece id tutsaydık Favorilerim ekranı onu gösteremezdi. Ayrıca böylece
  // favoriler internet yokken de görünür.
  static const String _favoritesKey = 'favorite_events_v2';
  static const String _themeKey = 'theme_mode';

  Future<List<EventModel>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_favoritesKey) ?? [];
    final result = <EventModel>[];
    for (final item in raw) {
      try {
        result.add(EventModel.fromJson(jsonDecode(item)));
      } catch (_) {
        // Bozuk bir kayıt tüm listeyi çökertmesin, onu atlıyoruz.
      }
    }
    return result;
  }

  Future<void> saveFavorites(List<EventModel> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _favoritesKey,
      favorites.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  /// 'light', 'dark' veya 'system'
  Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey);
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode);
  }
}
