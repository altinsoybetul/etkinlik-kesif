import 'package:intl/intl.dart';
import '../models/event_model.dart';

/// API'den gelen ISO tarihleri ("2026-10-21T18:00:00+03:00") okunabilir hale getirir.
/// Türkçe ay/gün adları için main() içinde initializeDateFormatting('tr_TR') çağrılıyor.
class DateFormatter {
  DateFormatter._();

  static String short(EventModel event) {
    final start = event.startDateTime;
    if (start == null) return event.date;
    return DateFormat('d MMM, HH:mm', 'tr_TR').format(start);
  }

  static String long(EventModel event) {
    final start = event.startDateTime;
    if (start == null) return event.date;
    final day = DateFormat('d MMMM y EEEE, HH:mm', 'tr_TR').format(start);
    final end = event.endDateTime;
    if (end == null) return day;
    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    final endText = sameDay
        ? DateFormat('HH:mm', 'tr_TR').format(end)
        : DateFormat('d MMMM, HH:mm', 'tr_TR').format(end);
    return '$day – $endText';
  }
}
