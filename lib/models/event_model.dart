class EventModel {
  final String id;
  final String title;
  // Liste uç noktası (/events) açıklama göndermiyor; sadece /events/{id} gönderiyor.
  // Bu yüzden null olabilir ve detay ekranında ayrıca çekilir.
  final String? description;
  final String location;
  final String date; // API'deki startDate 
  final String? endDate;
  final String category;
  final String imageUrl;
  final String organizer;
  final int? capacity;
  final int? registeredCount;
  final bool isOnline;
  final List<String> tags;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    required this.location,
    required this.date,
    this.endDate,
    required this.category,
    required this.imageUrl,
    required this.organizer,
    this.capacity,
    this.registeredCount,
    this.isOnline = false,
    this.tags = const [],
  });

  DateTime? get startDateTime => DateTime.tryParse(date)?.toLocal();
  DateTime? get endDateTime =>
      endDate == null ? null : DateTime.tryParse(endDate!)?.toLocal();

  bool get isFull =>
      capacity != null &&
      registeredCount != null &&
      registeredCount! >= capacity!;

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Başlıksız Etkinlik',
      description: json['description'],
      location: json['location'] ?? 'Konum Belirtilmedi',
      date: json['startDate'] ?? json['date'] ?? '',
      endDate: json['endDate'],
      category: json['category'] ?? 'Genel',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
      organizer: json['organizer'] ?? '',
      capacity: (json['capacity'] as num?)?.toInt(),
      registeredCount: (json['registeredCount'] as num?)?.toInt(),
      isOnline: json['isOnline'] == true,
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'startDate': date,
      'endDate': endDate,
      'category': category,
      'imageUrl': imageUrl,
      'organizer': organizer,
      'capacity': capacity,
      'registeredCount': registeredCount,
      'isOnline': isOnline,
      'tags': tags,
    };
  }
}

/// /events yanıtının bir sayfası: öğeler + "daha var mı" bilgisi.
class EventPage {
  final List<EventModel> items;
  final int page;
  final int total;
  final bool hasMore;

  EventPage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });
}
