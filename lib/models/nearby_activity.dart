class NearbyActivity {
  final String title;
  final String category;
  final String? duration;
  final String? imageUrl;
  final String? detailsUrl;
  final double? distanceKm;
  final bool ticketBooking;
  final String? ticketLink;

  NearbyActivity({
    required this.title,
    required this.category,
    this.duration,
    this.imageUrl,
    this.detailsUrl,
    this.distanceKm,
    required this.ticketBooking,
    this.ticketLink,
  });

  factory NearbyActivity.fromJson(Map<String, dynamic> json) {
    return NearbyActivity(
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      duration: _bucketToUi(json['durationBucket']?.toString() ?? ''),
      imageUrl: json['imageUrl']?.toString(),
      detailsUrl: json['detailsUrl']?.toString(),
      distanceKm: json['distanceKm'] != null 
          ? double.tryParse(json['distanceKm'].toString())
          : null,
      ticketBooking: json['ticketBooking'] == true || 
          json['ticketBooking']?.toString().toLowerCase() == 'true',
      ticketLink: json['ticketLink']?.toString(),
    );
  }

  static String _bucketToUi(String bucket) {
    switch (bucket) {
      case '<1h':
        return '<1 hour';
      case '1-2h':
        return '1-2 hours';
      case '2-3h':
        return '2-3 hours';
      case '3h+':
        return 'More than 3 hours';
      default:
        return '';
    }
  }
}