import 'package:event_app/main.dart';
import 'package:event_app/providers/event_provider.dart';
import 'package:event_app/providers/theme_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_api_service.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<FakeApiService> pumpApp(WidgetTester tester, {bool fail = false}) async {
    final api = FakeApiService()..shouldFail = fail;
    await tester.pumpWidget(MyApp(
      themeProvider: ThemeProvider(),
      eventProvider: EventProvider(apiService: api),
    ));
    await tester.pumpAndSettle();
    return api;
  }

  testWidgets('etkinlikler listelenir', (tester) async {
    await pumpApp(tester);
    expect(find.text('Etkinlikleri Keşfet'), findsOneWidget);
    expect(find.text('Flutter Atölyesi 0'), findsOneWidget);
  });

  testWidgets('hata durumunda Tekrar Dene ile liste gelir', (tester) async {
    final api = await pumpApp(tester, fail: true);
    expect(find.text('Tekrar Dene'), findsOneWidget);

    api.shouldFail = false;
    await tester.tap(find.text('Tekrar Dene'));
    await tester.pumpAndSettle();
    expect(find.text('Flutter Atölyesi 0'), findsOneWidget);
  });

  testWidgets('kalbe dokununca etkinlik Favorilerim sekmesinde görünür', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Favorilere ekle').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favorilerim'));
    await tester.pumpAndSettle();
    expect(find.text('Flutter Atölyesi 0'), findsOneWidget);
  });
}
