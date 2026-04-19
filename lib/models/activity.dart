class Activity {
  final String name;
  final String category;
  final String description;
  final double cost;
  final int durationMinutes;
  final String? imageUrl;
  final String? locationLink;
  final String? ticketLink;
  final bool ticketBooking;
  final double lat;
  final double lng;
  final String time;
  final String type;

  Activity({
    required this.name,
    required this.category,
    required this.description,
    required this.cost,
    required this.durationMinutes,
    this.imageUrl,
    this.locationLink,
    this.ticketLink,
    required this.ticketBooking,
    required this.lat,
    required this.lng,
    required this.time,
    required this.type,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      description: json['description']?.toString() ?? '',
      cost: (json['cost'] ?? 0).toDouble(),
      durationMinutes: (json['duration'] ?? json['duration_minutes'] ?? 60).toInt(),
      imageUrl: json['image_url']?.toString(),
      locationLink: json['location_link']?.toString(),
      ticketLink: json['ticket_link']?.toString(),
      ticketBooking: json['ticket_booking'] ?? false,
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      time: json['time']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'description': description,
    'cost': cost,
    'duration_minutes': durationMinutes,
    'image_url': imageUrl,
    'location_link': locationLink,
    'ticket_link': ticketLink,
    'ticket_booking': ticketBooking,
    'lat': lat,
    'lng': lng,
    'time': time,
    'type': type,
  };
}