import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/event_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Tarihlerde "Ekim", "Salı" gibi Türkçe adlar için.
  await initializeDateFormatting('tr_TR');

  // Tema seçimini uygulama çizilmeden önce okuyoruz; yoksa açılışta bir an
  // yanlış temada görünüp sonra değişirdi.
  final themeProvider = ThemeProvider();
  await themeProvider.load();

  runApp(MyApp(themeProvider: themeProvider));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  final EventProvider? eventProvider; // Testlerde sahte veriyle vermek için.

  const MyApp({super.key, required this.themeProvider, this.eventProvider});

  @override
  Widget build(BuildContext context) {
    // Provider'ları uygulamanın tepesine koyuyoruz; böylece altındaki
    // tüm ekranlar (Home, Detail, Favorites) bu verilere erişebilir.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(
          create: (_) => (eventProvider ?? EventProvider())..init(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Etkinlik Keşif',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: theme.mode,
          home: const MainNavigationScreen(),
        ),
      ),
    );
  }
}
