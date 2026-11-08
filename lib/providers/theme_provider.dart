import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider with ChangeNotifier {
  final StorageService _storageService;

  ThemeProvider({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final saved = await _storageService.getThemeMode();
    _mode = ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
    notifyListeners();
  }

  Future<void> cycle() async {
    _mode = switch (_mode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    notifyListeners();
    await _storageService.saveThemeMode(_mode.name);
  }

  IconData get icon => switch (_mode) {
        ThemeMode.system => Icons.brightness_auto,
        ThemeMode.light => Icons.light_mode,
        ThemeMode.dark => Icons.dark_mode,
      };

  String get label => switch (_mode) {
        ThemeMode.system => 'Tema: Sistem',
        ThemeMode.light => 'Tema: Açık',
        ThemeMode.dark => 'Tema: Koyu',
      };
}
